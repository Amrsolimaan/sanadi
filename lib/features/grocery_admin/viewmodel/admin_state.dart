import 'package:equatable/equatable.dart';
import 'package:sanadi/features/auth/model/user_model.dart';
import 'package:sanadi/features/doctors/model/doctor_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final UserModel currentAdmin;
  final List<UserModel> users;
  final Map<String, int> userStats;
  final Map<String, int> todayStats;
  final Map<String, dynamic> dashboardStats;
  final String selectedFilter;

  final List<DoctorModel> topDoctors;
  final List<UserModel> activeUsers;
  final List<Map<String, dynamic>> interestTrendsDoctors;
  final List<Map<String, dynamic>> interestTrendsProducts;

  const AdminLoaded({
    required this.currentAdmin,
    required this.users,
    required this.userStats,
    required this.todayStats,
    required this.dashboardStats,
    this.selectedFilter = 'all',
    this.topDoctors = const [],
    this.activeUsers = const [],
    this.interestTrendsDoctors = const [],
    this.interestTrendsProducts = const [],
  });

  List<UserModel> get filteredUsers {
    switch (selectedFilter) {
      case 'users':
        return users.where((u) => u.role == UserRole.user).toList();
      case 'admins':
        return users
            .where((u) =>
                u.role == UserRole.admin || u.role == UserRole.superAdmin)
            .toList();
      case 'moderators':
        return users.where((u) => u.role == UserRole.moderator).toList();
      case 'active':
        return users.where((u) => u.isActive).toList();
      case 'inactive':
        return users.where((u) => !u.isActive).toList();
      default:
        return users;
    }
  }

  AdminLoaded copyWith({
    UserModel? currentAdmin,
    List<UserModel>? users,
    Map<String, int>? userStats,
    Map<String, int>? todayStats,
    Map<String, dynamic>? dashboardStats,
    String? selectedFilter,
    List<DoctorModel>? topDoctors,
    List<UserModel>? activeUsers,
    List<Map<String, dynamic>>? interestTrendsDoctors,
    List<Map<String, dynamic>>? interestTrendsProducts,
  }) {
    return AdminLoaded(
      currentAdmin: currentAdmin ?? this.currentAdmin,
      users: users ?? this.users,
      userStats: userStats ?? this.userStats,
      todayStats: todayStats ?? this.todayStats,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      topDoctors: topDoctors ?? this.topDoctors,
      activeUsers: activeUsers ?? this.activeUsers,
      interestTrendsDoctors:
          interestTrendsDoctors ?? this.interestTrendsDoctors,
      interestTrendsProducts:
          interestTrendsProducts ?? this.interestTrendsProducts,
    );
  }

  @override
  List<Object?> get props => [
        currentAdmin,
        users,
        userStats,
        todayStats,
        dashboardStats,
        selectedFilter,
        topDoctors,
        activeUsers,
        interestTrendsDoctors,
        interestTrendsProducts,
      ];
}

class AdminError extends AdminState {
  final String message;

  const AdminError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminAccessDenied extends AdminState {
  final String message;

  const AdminAccessDenied({this.message = 'ليس لديك صلاحية للوصول'});

  @override
  List<Object?> get props => [message];
}
