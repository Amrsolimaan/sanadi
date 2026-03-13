import 'dart:isolate';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/medications/model/medication_model.dart';
import '../../features/medications/model/notification_event_model.dart';
import 'notification_service.dart';
import 'notification_history_service.dart';

/// خدمة المنبهات للأدوية
class AlarmService {
  static const String _isolateName = 'medication_alarm_isolate';
  static final NotificationService _notificationService = NotificationService();

  /// تهيئة خدمة المنبهات
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await AndroidAlarmManager.initialize();
      await _notificationService.initialize();
      debugPrint('✅ AlarmService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize AlarmService: $e');
    }
  }

  /// جدولة منبه لدواء مع إشعار
  static Future<void> scheduleMedicationAlarm({
    required MedicationModel medication,
    required String time,
    required int alarmId,
  }) async {
    try {
      // تحليل الوقت
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // حساب الوقت القادم
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // إذا الوقت مضى اليوم، جدوله للغد
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // جدولة الإشعار
      await _notificationService.scheduleMedicationNotification(
        medication: medication,
        time: time,
        notificationId: alarmId,
      );

      // جدولة المنبه (كـ backup)
      await AndroidAlarmManager.oneShotAt(
        scheduledDate,
        alarmId,
        _alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'medicationId': medication.id,
          'medicationName': medication.name,
          'dose': medication.dose,
          'time': time,
          'purpose': medication.purpose ?? '',
        },
      );

      debugPrint(
          '✅ Alarm scheduled for ${medication.name} at $scheduledDate (ID: $alarmId)');
    } catch (e) {
      debugPrint('❌ Failed to schedule alarm: $e');
    }
  }

  /// جدولة منبه يومي متكرر
  static Future<void> scheduleDailyAlarm({
    required MedicationModel medication,
    required String time,
    required int alarmId,
  }) async {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // جدولة الإشعار المتكرر
      await _notificationService.scheduleMedicationNotification(
        medication: medication,
        time: time,
        notificationId: alarmId,
      );

      // جدولة المنبه المتكرر
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        _alarmCallback,
        startAt: scheduledDate,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'medicationId': medication.id,
          'medicationName': medication.name,
          'dose': medication.dose,
          'time': time,
          'purpose': medication.purpose ?? '',
        },
      );

      debugPrint(
          '✅ Daily alarm scheduled for ${medication.name} at $time (ID: $alarmId)');
    } catch (e) {
      debugPrint('❌ Failed to schedule daily alarm: $e');
    }
  }

  /// إلغاء منبه
  static Future<void> cancelAlarm(int alarmId) async {
    try {
      await AndroidAlarmManager.cancel(alarmId);
      await _notificationService.cancelNotification(alarmId);
      debugPrint('🗑️ Alarm cancelled (ID: $alarmId)');
    } catch (e) {
      debugPrint('❌ Failed to cancel alarm: $e');
    }
  }

  /// إلغاء جميع منبهات دواء معين
  static Future<void> cancelMedicationAlarms(MedicationModel medication) async {
    for (int i = 0; i < medication.times.length; i++) {
      final alarmId = _generateAlarmId(medication.id, medication.times[i]);
      await cancelAlarm(alarmId);
    }
  }

  /// إلغاء جميع المنبهات لمجموعة من الأدوية (عند تسجيل الخروج)
  static Future<void> cancelAllAlarmsForMedications(
      List<MedicationModel> medications) async {
    for (final med in medications) {
      await cancelMedicationAlarms(med);
    }
    debugPrint(
        '🗑️ All alarms cancelled for ${medications.length} medications');
  }

  /// جدولة جميع منبهات دواء
  static Future<void> scheduleAllAlarmsForMedication(
      MedicationModel medication) async {
    if (!medication.isActive) return;

    for (final time in medication.times) {
      final alarmId = _generateAlarmId(medication.id, time);

      if (medication.frequency == MedicationFrequency.daily) {
        await scheduleDailyAlarm(
          medication: medication,
          time: time,
          alarmId: alarmId,
        );
      } else if (medication.frequency == MedicationFrequency.specificDays) {
        // للأيام المحددة
        if (medication.shouldTakeToday()) {
          await scheduleMedicationAlarm(
            medication: medication,
            time: time,
            alarmId: alarmId,
          );
        }
      } else {
        // as needed - لا نجدول منبه
        debugPrint(
            '⏭️ Skipping alarm for as-needed medication: ${medication.name}');
      }
    }
  }

  /// توليد ID فريد للمنبه
  static int _generateAlarmId(String medicationId, String time) {
    final combined = '$medicationId-$time';
    return combined.hashCode.abs() % 2147483647;
  }

  /// Callback عند تشغيل المنبه
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(
      int alarmId, Map<String, dynamic> params) async {
    debugPrint('🔔 ALARM TRIGGERED! ID: $alarmId');
    debugPrint('   Medication: ${params['medicationName']}');
    debugPrint('   Dose: ${params['dose']}');
    debugPrint('   Time: ${params['time']}');

    // ✅ التحقق من المستخدم وتسجيل الحدث
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    final historyService = NotificationHistoryService();

    if (currentUser != null) {
      // ✅ المستخدم مسجل - أظهر الإشعار وسجّل "alarmRang"
      debugPrint('✅ User logged in - showing notification');

      try {
        final notificationService = NotificationService();
        await notificationService.initialize();
        await notificationService.showInstantNotification(
          title: '💊 ${params['medicationName']}',
          body: 'Time to take ${params['dose']}',
          payload: '${params['medicationId']}|${params['time']}',
        );

        // تسجيل: المنبه رن بنجاح
        await historyService.logNotificationEvent(
          medicationId: params['medicationId'] ?? '',
          medicationName: params['medicationName'] ?? '',
          scheduledTime: params['time'] ?? '',
          eventType: NotificationEventType.alarmRang,
        );
      } catch (e) {
        debugPrint('❌ Failed to show notification: $e');
      }
    } else {
      // ❌ المستخدم غير مسجل - لا إشعار (وسجّل كـ MISSED)
      debugPrint('⚠️ User NOT logged in - alarm MISSED');
      debugPrint('⏰ MISSED: ${params['medicationName']} at ${params['time']}');
      // ملاحظة: لن يُحفظ في Firestore بدون userId
    }

    // إرسال للـ UI
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_isolateName);
    sendPort?.send({
      'type': 'medication_alarm',
      'alarmId': alarmId,
      'params': params,
    });
  }

  /// الاستماع للمنبهات من الـ UI
  static void listenForAlarms(Function(Map<String, dynamic>) onAlarm) {
    final ReceivePort receivePort = ReceivePort();

    // إزالة أي port قديم
    IsolateNameServer.removePortNameMapping(_isolateName);

    // تسجيل port جديد
    IsolateNameServer.registerPortWithName(receivePort.sendPort, _isolateName);

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        onAlarm(message);
      }
    });

    debugPrint('👂 Listening for alarms...');
  }

  /// إيقاف الاستماع للمنبهات
  static void stopListening() {
    IsolateNameServer.removePortNameMapping(_isolateName);
    debugPrint('🛑 Stopped listening for alarms');
  }
}
