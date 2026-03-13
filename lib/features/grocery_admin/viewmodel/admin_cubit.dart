import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanadi/features/auth/model/user_model.dart';
import 'package:sanadi/services/firestore/admin_service_addition.dart';
import 'package:sanadi/services/firestore/analytics_service.dart';

import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminService _adminService = AdminService();
  UserModel? _currentAdmin;

  AdminCubit() : super(AdminInitial());

  UserModel? get currentAdmin => _currentAdmin;

  /// تحميل بيانات لوحة التحكم
  Future<void> loadDashboard(UserModel admin) async {
    emit(AdminLoading());

    try {
      if (!admin.hasAdminAccess) {
        emit(const AdminAccessDenied());
        return;
      }

      _currentAdmin = admin;

      final users = await _adminService.getAllUsers();
      final userStats = await _adminService.getUserStats();
      final todayStats = await _adminService.getTodayStats();
      final dashboardStats = await _adminService.getDashboardStats();

      // ✅ Load Analytics Data
      final analyticsService = AnalyticsService(); // Best to inject, but locally instantiating for now
      final topDoctors = await analyticsService.getTopDoctors();
      final activeUsers = await analyticsService.getMostActiveUsers();
      final interestDoctors = await analyticsService.getTopFavoritedDoctors();
      final interestProducts = await analyticsService.getTopCartProducts();

      emit(AdminLoaded(
        currentAdmin: admin,
        users: users,
        userStats: userStats,
        todayStats: todayStats,
        dashboardStats: dashboardStats,
        topDoctors: topDoctors,
        activeUsers: activeUsers,
        interestTrendsDoctors: interestDoctors,
        interestTrendsProducts: interestProducts,
      ));
    } catch (e) {
      emit(AdminError(message: 'فشل في تحميل البيانات: $e'));
    }
  }

  Future<void> refresh() async {
    if (_currentAdmin == null) return;
    try {
      await loadDashboard(_currentAdmin!);
    } catch (e) {
      emit(AdminError(message: 'فشل في تحديث البيانات: $e'));
    }
  }

  void changeFilter(String filter) {
    final currentState = state;
    if (currentState is AdminLoaded) {
      emit(currentState.copyWith(selectedFilter: filter));
    }
  }

  Future<void> changeUserRole(String uid, UserRole newRole) async {
    final currentState = state;
    if (currentState is! AdminLoaded) return;

    if (!currentState.currentAdmin.canManageUsers()) {
      emit(const AdminError(message: 'ليس لديك صلاحية لتغيير الأدوار'));
      // Return to loaded state after error message (optional, or let UI handle the error toast)
      emit(currentState);
      return;
    }

    emit(AdminLoading());
    try {
      final success = await _adminService.setUserRole(uid, newRole);
      if (success) {
        await refresh();
      } else {
        emit(const AdminError(message: 'فشل في تغيير الدور'));
        emit(currentState);
      }
    } catch (e) {
      emit(AdminError(message: 'حدث خطأ أثناء تغيير الدور: $e'));
      emit(currentState);
    }
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    final currentState = state;
    if (currentState is! AdminLoaded) return;

    if (!currentState.currentAdmin.canManageUsers()) {
      emit(const AdminError(message: 'ليس لديك صلاحية'));
      emit(currentState);
      return;
    }

    emit(AdminLoading());
    try {
      final success = await _adminService.toggleUserActive(uid, isActive);
      if (success) {
        await refresh();
      } else {
        emit(const AdminError(message: 'فشل في تحديث الحساب'));
        emit(currentState);
      }
    } catch (e) {
      emit(AdminError(message: 'حدث خطأ أثناء تحديث الحساب: $e'));
      emit(currentState);
    }
  }

  Future<void> deleteUser(String uid) async {
    final currentState = state;
    if (currentState is! AdminLoaded) return;

    if (!currentState.currentAdmin.canManageUsers()) {
      emit(const AdminError(message: 'ليس لديك صلاحية للحذف'));
      emit(currentState);
      return;
    }

    emit(AdminLoading());
    try {
      final success = await _adminService.deleteUser(uid);
      if (success) {
        await refresh();
      } else {
        emit(const AdminError(message: 'فشل في حذف المستخدم'));
        emit(currentState);
      }
    } catch (e) {
      emit(AdminError(message: 'حدث خطأ أثناء حذف المستخدم: $e'));
      emit(currentState);
    }
  }

  void searchUsers(String query) {
    final currentState = state;
    if (currentState is! AdminLoaded) return;

    if (query.isEmpty) {
      refresh();
      return;
    }

    final filtered = _adminService.searchUsers(currentState.users, query);
    emit(currentState.copyWith(users: filtered));
  }

  bool canPerformAction(String action) {
    if (_currentAdmin == null) return false;

    switch (action) {
      case 'view':
        return _currentAdmin!.canView();
      case 'add':
        return _currentAdmin!.canAdd();
      case 'edit':
        return _currentAdmin!.canEdit();
      case 'delete':
        return _currentAdmin!.canDelete();
      case 'manage_users':
        return _currentAdmin!.canManageUsers();
      case 'manage_admins':
        return _currentAdmin!.canManageAdmins();
      case 'export':
        return _currentAdmin!.canExportData();
      default:
        return false;
    }
  }
}
