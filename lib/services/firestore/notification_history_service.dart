import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/medications/model/notification_event_model.dart';

class NotificationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// الحصول على userId الحالي
  String? get _userId => _auth.currentUser?.uid;

  /// الحصول على collection الإشعارات للمستخدم
  CollectionReference _getNotificationCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notification_events');
  }

  /// تسجيل حدث إشعار جديد
  Future<void> logNotificationEvent({
    required String medicationId,
    required String medicationName,
    required String scheduledTime,
    required NotificationEventType eventType,
    String? notes,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) {
        // إذا لم يكن هناك مستخدم مسجل دخول، نسجل كـ "missed"
        // ولكن بدون حفظ في Firestore لأن ليس لدينا userId
        print('⚠️ No user logged in - cannot log notification event');
        return;
      }

      final event = NotificationEventModel(
        id: '', // سيتم توليده من Firestore
        userId: userId,
        medicationId: medicationId,
        medicationName: medicationName,
        scheduledTime: scheduledTime,
        eventType: eventType,
        timestamp: DateTime.now(),
        notes: notes,
      );

      await _getNotificationCollection(userId).add(event.toFirestore());
      print('✅ Notification event logged: ${eventType.name}');
    } catch (e) {
      print('❌ Error logging notification event: $e');
    }
  }

  /// الحصول على سجل الإشعارات للمستخدم
  Future<List<NotificationEventModel>> getUserNotificationHistory({
    int? limitCount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) return [];

      Query query = _getNotificationCollection(userId)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (limitCount != null) {
        query = query.limit(limitCount);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => NotificationEventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting notification history: $e');
      return [];
    }
  }

  /// الحصول على المنبهات الفائتة فقط
  Future<List<NotificationEventModel>> getMissedAlarms({
    DateTime? since,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) return [];

      Query query = _getNotificationCollection(userId)
          .where('eventType', isEqualTo: NotificationEventType.alarmMissed.name)
          .orderBy('timestamp', descending: true);

      if (since != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => NotificationEventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting missed alarms: $e');
      return [];
    }
  }

  /// حذف الأحداث القديمة (اختياري - للصيانة)
  Future<void> deleteOldEvents({int daysToKeep = 30}) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _getNotificationCollection(userId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Deleted ${snapshot.docs.length} old notification events');
    } catch (e) {
      print('❌ Error deleting old events: $e');
    }
  }

  /// الحصول على الأحداث حسب نوع معين
  Future<List<NotificationEventModel>> getEventsByType(
    NotificationEventType eventType, {
    int? limit,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) return [];

      Query query = _getNotificationCollection(userId)
          .where('eventType', isEqualTo: eventType.name)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => NotificationEventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting events by type: $e');
      return [];
    }
  }

  /// Stream للاستماع للتحديثات الفورية
  Stream<List<NotificationEventModel>> watchNotificationHistory({
    int limit = 50,
  }) {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _getNotificationCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationEventModel.fromFirestore(doc))
            .toList());
  }
}
