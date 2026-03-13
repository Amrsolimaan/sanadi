import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../features/medications/model/medication_model.dart';

/// خدمة الإشعارات المحلية للأدوية
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// طلب أذونات Android 13+
  Future<void> _requestAndroidPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // يمكنك إضافة navigation هنا
  }

  /// جدولة إشعار لدواء
  Future<void> scheduleMedicationNotification({
    required MedicationModel medication,
    required String time,
    required int notificationId,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // حساب الوقت التالي للإشعار
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // إذا الوقت مضى، جدوله للغد
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // إعدادات الإشعار
      final androidDetails = AndroidNotificationDetails(
        'medication_channel',
        'Medication Reminders',
        channelDescription: 'Reminders to take your medications',
        importance: Importance.high,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('medication_alarm'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Time to take ${medication.name} - ${medication.dose}',
          contentTitle: '💊 ${medication.name}',
          summaryText: medication.purpose ?? 'Medication Reminder',
        ),
        actions: [
          const AndroidNotificationAction(
            'taken',
            '✓ Taken',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'skip',
            'Skip',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'medication_alarm.aiff',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // جدولة الإشعار المتكرر يومياً
      if (medication.frequency == MedicationFrequency.daily) {
        await _notifications.zonedSchedule(
          notificationId,
          '💊 ${medication.name}',
          'Time to take ${medication.dose}',
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: '${medication.id}|$time',
        );
      } else {
        // إشعار لمرة واحدة
        await _notifications.zonedSchedule(
          notificationId,
          '💊 ${medication.name}',
          'Time to take ${medication.dose}',
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '${medication.id}|$time',
        );
      }

      debugPrint(
          '✅ Notification scheduled for ${medication.name} at $scheduledDate (ID: $notificationId)');
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  /// جدولة جميع إشعارات دواء معين
  Future<void> scheduleAllNotificationsForMedication(
      MedicationModel medication) async {
    if (!medication.isActive) return;

    for (int i = 0; i < medication.times.length; i++) {
      final time = medication.times[i];
      final notificationId = _generateNotificationId(medication.id, time);

      await scheduleMedicationNotification(
        medication: medication,
        time: time,
        notificationId: notificationId,
      );
    }
  }

  /// إلغاء إشعار معين
  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
    debugPrint('🗑️ Notification cancelled (ID: $notificationId)');
  }

  /// إلغاء جميع إشعارات دواء معين
  Future<void> cancelMedicationNotifications(MedicationModel medication) async {
    for (final time in medication.times) {
      final notificationId = _generateNotificationId(medication.id, time);
      await cancelNotification(notificationId);
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  /// عرض إشعار فوري (للاختبار)
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// توليد ID فريد للإشعار
  int _generateNotificationId(String medicationId, String time) {
    final combined = '$medicationId-$time';
    return combined.hashCode.abs() % 2147483647;
  }
}
