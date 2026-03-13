import 'package:cloud_firestore/cloud_firestore.dart';

/// أنواع الأحداث التي يمكن تسجيلها
enum NotificationEventType {
  alarmRang,        // المنبه رن
  alarmMissed,      // المنبه فات (مستخدم غير مسجل دخول أو هاتف مغلق)
  medicationTaken,  // تم تناول الدواء
  medicationSkipped, // تم تخطي الدواء
}

class NotificationEventModel {
  final String id;
  final String userId;
  final String medicationId;
  final String medicationName;
  final String scheduledTime;
  final NotificationEventType eventType;
  final DateTime timestamp;
  final String? notes;

  NotificationEventModel({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.eventType,
    required this.timestamp,
    this.notes,
  });

  /// Create from Firestore document
  factory NotificationEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationEventModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      scheduledTime: data['scheduledTime'] ?? '',
      eventType: _parseEventType(data['eventType']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime,
      'eventType': eventType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  /// Parse event type from string
  static NotificationEventType _parseEventType(String? type) {
    switch (type) {
      case 'alarmRang':
        return NotificationEventType.alarmRang;
      case 'alarmMissed':
        return NotificationEventType.alarmMissed;
      case 'medicationTaken':
        return NotificationEventType.medicationTaken;
      case 'medicationSkipped':
        return NotificationEventType.medicationSkipped;
      default:
        return NotificationEventType.alarmMissed;
    }
  }

  /// Get user-friendly label for event type
  String getEventLabel(String lang) {
    switch (eventType) {
      case NotificationEventType.alarmRang:
        return lang == 'ar' ? 'رن المنبه' : 'Alarm Rang';
      case NotificationEventType.alarmMissed:
        return lang == 'ar' ? 'منبه فائت' : 'Missed Alarm';
      case NotificationEventType.medicationTaken:
        return lang == 'ar' ? 'تم التناول' : 'Taken';
      case NotificationEventType.medicationSkipped:
        return lang == 'ar' ? 'تم التخطي' : 'Skipped';
    }
  }

  /// Get icon for event type
  String getEventIcon() {
    switch (eventType) {
      case NotificationEventType.alarmRang:
        return '🔔';
      case NotificationEventType.alarmMissed:
        return '⏰';
      case NotificationEventType.medicationTaken:
        return '✅';
      case NotificationEventType.medicationSkipped:
        return '⏭️';
    }
  }
}
