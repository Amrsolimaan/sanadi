import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/medications/model/medication_model.dart';
import '../../features/medications/model/medication_log_model.dart';
import '../../features/medications/model/notification_event_model.dart';
import 'notification_history_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ الحصول على userId مع انتظار حتى يكون جاهزاً
  Future<String> _getValidUserId() async {
    // أولاً: تحقق من المستخدم الحالي
    var user = _auth.currentUser;

    if (user != null) {
      print('✅ MedicationService - User found immediately: ${user.uid}');
      return user.uid;
    }

    print('⏳ MedicationService - Waiting for auth state...');

    // ثانياً: انتظر authStateChanges لأن Google Sign-In قد يتأخر
    try {
      user = await _auth
          .authStateChanges()
          .where((user) => user != null)
          .first
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Auth timeout'),
          );

      if (user != null) {
        print('✅ MedicationService - User found after waiting: ${user.uid}');
        return user.uid;
      }
    } catch (e) {
      print('❌ MedicationService - Auth state error: $e');
    }

    // ثالثاً: محاولة أخيرة
    await Future.delayed(const Duration(milliseconds: 500));
    user = _auth.currentUser;

    if (user != null) {
      print('✅ MedicationService - User found on retry: ${user.uid}');
      return user.uid;
    }

    print('❌ MedicationService - User not authenticated');
    throw Exception('User not authenticated. Please login again.');
  }

  /// ✅ الحصول على collection الأدوية بشكل آمن
  CollectionReference _getMedicationsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('medications');
  }

  /// ✅ الحصول على collection السجلات بشكل آمن
  CollectionReference _getLogsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medication_logs');
  }

  /// إضافة دواء جديد
  Future<String> addMedication(MedicationModel medication) async {
    final userId = await _getValidUserId();

    final data = medication.toFirestore();
    data['visitorId'] = userId;

    print('📝 Adding medication for user: $userId');
    final doc = await _getMedicationsCollection(userId).add(data);
    print('✅ Medication added with ID: ${doc.id}');
    return doc.id;
  }

  /// تحديث دواء
  Future<void> updateMedication(String id, MedicationModel medication) async {
    final userId = await _getValidUserId();

    await _getMedicationsCollection(userId)
        .doc(id)
        .update(medication.toFirestore());
    print('✅ Medication $id updated');
  }

  /// الحصول على جميع الأدوية النشطة
  Future<List<MedicationModel>> getMedications() async {
    try {
      final userId = await _getValidUserId();

      print('📖 Getting medications for user: $userId');
      final snapshot = await _getMedicationsCollection(userId).get();
      print('📊 Found ${snapshot.docs.length} total documents');

      final medications = snapshot.docs
          .map((doc) => MedicationModel.fromFirestore(doc))
          .where((med) => med.isActive)
          .toList();

      print('✅ Active medications: ${medications.length}');

      // ترتيب حسب تاريخ الإنشاء (الأحدث أولاً)
      medications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return medications;
    } catch (e) {
      print('❌ Error getting medications: $e');
      return [];
    }
  }

  /// الحصول على أدوية اليوم
  Future<List<MedicationModel>> getTodayMedications() async {
    final medications = await getMedications();
    return medications.where((med) => med.shouldTakeToday()).toList();
  }

  /// الحصول على دواء بالـ ID
  Future<MedicationModel?> getMedicationById(String id) async {
    try {
      final userId = await _getValidUserId();
      final doc = await _getMedicationsCollection(userId).doc(id).get();
      if (!doc.exists) return null;
      return MedicationModel.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting medication by ID: $e');
      return null;
    }
  }

  /// حذف دواء (soft delete)
  Future<void> deleteMedication(String id) async {
    final userId = await _getValidUserId();
    await _getMedicationsCollection(userId).doc(id).update({'isActive': false});
    print('✅ Medication $id soft deleted');
  }

  /// حذف دواء نهائياً
  Future<void> permanentlyDeleteMedication(String id) async {
    final userId = await _getValidUserId();
    await _getMedicationsCollection(userId).doc(id).delete();
    print('✅ Medication $id permanently deleted');
  }

  /// تسجيل تناول الدواء
  Future<String> logMedicationTaken(
    String medicationId,
    String scheduledTime,
    String medicationName,
  ) async {
    final userId = await _getValidUserId();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // التحقق من عدم وجود سجل مسبق لنفس الدواء والوقت
    final existingLog =
        await _getExistingLog(medicationId, scheduledTime, todayStart);

    if (existingLog != null) {
      // تحديث السجل الموجود
      await _getLogsCollection(userId).doc(existingLog.id).update({
        'status': 'taken',
        'takenAt': Timestamp.now(),
      });
      return existingLog.id;
    }

    // إنشاء سجل جديد
    final doc = await _getLogsCollection(userId).add({
      'visitorId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime,
      'takenAt': Timestamp.now(),
      'status': 'taken',
      'date': Timestamp.fromDate(todayStart),
    });

    // ✅ تسجيل حدث الإشعار: تم تناول الدواء
    final historyService = NotificationHistoryService();
    await historyService.logNotificationEvent(
      medicationId: medicationId,
      medicationName: medicationName,
      scheduledTime: scheduledTime,
      eventType: NotificationEventType.medicationTaken,
    );

    return doc.id;
  }

  /// تسجيل تخطي الدواء
  Future<String> logMedicationSkipped(
    String medicationId,
    String scheduledTime,
    String medicationName,
  ) async {
    final userId = await _getValidUserId();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // التحقق من عدم وجود سجل مسبق
    final existingLog =
        await _getExistingLog(medicationId, scheduledTime, todayStart);

    if (existingLog != null) {
      await _getLogsCollection(userId).doc(existingLog.id).update({
        'status': 'skipped',
        'takenAt': null,
      });
      return existingLog.id;
    }

    final doc = await _getLogsCollection(userId).add({
      'visitorId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime,
      'takenAt': null,
      'status': 'skipped',
      'date': Timestamp.fromDate(todayStart),
    });

    // ✅ تسجيل حدث الإشعار: تم تخطي الدواء
    final historyService = NotificationHistoryService();
    await historyService.logNotificationEvent(
      medicationId: medicationId,
      medicationName: medicationName,
      scheduledTime: scheduledTime,
      eventType: NotificationEventType.medicationSkipped,
    );

    return doc.id;
  }

  /// الحصول على سجل موجود
  Future<MedicationLogModel?> _getExistingLog(
    String medicationId,
    String scheduledTime,
    DateTime date,
  ) async {
    try {
      final logs = await getTodayLogs();
      return logs.cast<MedicationLogModel?>().firstWhere(
            (log) =>
                log?.medicationId == medicationId &&
                log?.scheduledTime == scheduledTime,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  /// الحصول على سجلات اليوم
  Future<List<MedicationLogModel>> getTodayLogs() async {
    try {
      final userId = await _getValidUserId();
      final now = DateTime.now();

      final snapshot = await _getLogsCollection(userId).get();

      return snapshot.docs
          .map((doc) => MedicationLogModel.fromFirestore(doc))
          .where((log) =>
              log.date.year == now.year &&
              log.date.month == now.month &&
              log.date.day == now.day)
          .toList();
    } catch (e) {
      print('❌ Error getting today logs: $e');
      return [];
    }
  }

  /// الحصول على سجلات فترة معينة
  Future<List<MedicationLogModel>> getLogsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = await _getValidUserId();

      final snapshot = await _getLogsCollection(userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs
          .map((doc) => MedicationLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting logs for date range: $e');
      return [];
    }
  }

  /// حساب نسبة الالتزام
  Future<double> getComplianceRate({int days = 7}) async {
    try {
      // التحقق من وجود مستخدم
      await _getValidUserId();

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final logs = await getLogsForDateRange(startDate, now);

      if (logs.isEmpty) return 0;

      final takenCount =
          logs.where((l) => l.status == MedicationLogStatus.taken).length;

      return takenCount / logs.length;
    } catch (e) {
      print('❌ Error calculating compliance rate: $e');
      return 0;
    }
  }
}
