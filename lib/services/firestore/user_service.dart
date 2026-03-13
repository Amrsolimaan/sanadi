import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/model/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // إنشاء مستخدم جديد
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // الحصول على بيانات مستخدم بواسطة UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  // ✅ التحقق من وجود رقم الهاتف
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking phone number: $e');
    }
  }

  // ✅ الحصول على المستخدم من رقم الهاتف
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return UserModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Error getting user by phone: $e');
    }
  }

  // تحديث بيانات المستخدم
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // ✅ تحديث حقول محددة فقط (لتجنب مشاكل الصلاحيات مع الـ Role)
  Future<void> updateSpecificFields(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating user fields: $e');
    }
  }

  // حذف مستخدم
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}
