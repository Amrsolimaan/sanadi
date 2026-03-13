import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanadi/features/auth/model/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// الحصول على جميع المستخدمين
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// إحصائيات المستخدمين
  Future<Map<String, int>> getUserStats() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      int totalUsers = snapshot.docs.length;
      int activeUsers = 0;
      int admins = 0;
      int regularUsers = 0;

      for (var doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data());

        if (user.isActive) activeUsers++;

        if (user.role == UserRole.admin || user.role == UserRole.superAdmin) {
          admins++;
        } else {
          regularUsers++;
        }
      }

      return {
        'total': totalUsers,
        'active': activeUsers,
        'admins': admins,
        'users': regularUsers,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'total': 0,
        'active': 0,
        'admins': 0,
        'users': 0,
      };
    }
  }

  /// إحصائيات اليوم
  Future<Map<String, int>> getTodayStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // المستخدمين الجدد اليوم
      final newUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      int newOrders = 0;
      int newAppointments = 0;

      // الطلبات الجديدة اليوم
      try {
        final ordersSnapshot = await _firestore
            .collection('grocery_orders')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        newOrders = ordersSnapshot.docs.length;
      } catch (e) {
        // Collection might not exist
      }

      // الحجوزات الجديدة اليوم
      try {
        final appointmentsSnapshot = await _firestore
            .collectionGroup('appointments')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        newAppointments = appointmentsSnapshot.docs.length;
      } catch (e) {
        // Collection might not exist
      }

      return {
        'newUsers': newUsersSnapshot.docs.length,
        'newOrders': newOrders,
        'newAppointments': newAppointments,
      };
    } catch (e) {
      print('Error getting today stats: $e');
      return {
        'newUsers': 0,
        'newOrders': 0,
        'newAppointments': 0,
      };
    }
  }

  /// إجمالي الإحصائيات للوحة التحكم
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // إجمالي المستخدمين
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // إجمالي طلبات البقالة والإيرادات
      int totalOrders = 0;
      double totalRevenue = 0;
      try {
        final ordersSnapshot =
            await _firestore.collection('grocery_orders').get();
        totalOrders = ordersSnapshot.docs.length;
        for (var doc in ordersSnapshot.docs) {
          totalRevenue += (doc.data()['total'] ?? 0).toDouble();
        }
      } catch (e) {
        // Collection might not exist
      }

      // إجمالي الحجوزات
      int totalAppointments = 0;
      try {
        final appointmentsSnapshot =
            await _firestore.collectionGroup('appointments').get();
        totalAppointments = appointmentsSnapshot.docs.length;
      } catch (e) {
        // Collection might not exist
      }

      return {
        'totalUsers': totalUsers,
        'totalOrders': totalOrders,
        'totalAppointments': totalAppointments,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalOrders': 0,
        'totalAppointments': 0,
        'totalRevenue': 0.0,
      };
    }
  }

  /// تغيير دور المستخدم
  Future<bool> setUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error setting user role: $e');
      return false;
    }
  }

  /// تفعيل/تعطيل حساب المستخدم
  Future<bool> toggleUserActive(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling user active: $e');
      return false;
    }
  }

  /// حذف مستخدم
  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// البحث في المستخدمين
  List<UserModel> searchUsers(List<UserModel> users, String query) {
    final lowerQuery = query.toLowerCase();
    return users.where((user) {
      return user.fullName.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery) ||
          user.phone.contains(query);
    }).toList();
  }

  /// تصفية المستخدمين حسب الدور
  List<UserModel> filterByRole(List<UserModel> users, UserRole role) {
    return users.where((user) => user.role == role).toList();
  }

  /// تصفية المستخدمين النشطين
  List<UserModel> filterActive(List<UserModel> users, bool activeOnly) {
    if (!activeOnly) return users;
    return users.where((user) => user.isActive).toList();
  }
}
