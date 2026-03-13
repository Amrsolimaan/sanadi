import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/medications/model/medication_model.dart';
import 'alarm_service.dart';
import 'medication_service.dart';

/// خدمة لإدارة المنبهات بشكل مستمر حتى عند تسجيل الخروج
class PersistentAlarmService {
  static const String _alarmsKey = 'persistent_alarms';
  static const String _lastSyncKey = 'last_alarm_sync';

  /// حفظ معلومات المنبهات في SharedPreferences
  static Future<void> saveMedicationAlarms(
      List<MedicationModel> medications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsData = medications
          .where((med) => med.isActive)
          .map((med) => {
                'id': med.id,
                'name': med.name,
                'dose': med.dose,
                'times': med.times,
                'frequency': med.frequency.toString(),
                'specificDays': med.specificDays,
                'purpose': med.purpose ?? '',
              })
          .toList();

      await prefs.setString(_alarmsKey, alarmsData.toString());
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ Saved ${alarmsData.length} medication alarms to storage');
    } catch (e) {
      debugPrint('❌ Failed to save alarms: $e');
    }
  }

  /// جدولة جميع المنبهات من Firebase (للمستخدم المسجل)
  static Future<void> scheduleAllAlarmsForUser(String userId) async {
    try {
      // 1️⃣ إلغاء جميع المنبهات القديمة أولاً
      await cancelAllExistingAlarms();
      
      final medicationService = MedicationService();
      final medications = await medicationService.getMedications();

      if (medications.isEmpty) {
        debugPrint('ℹ️ No medications found for user');
        await clearSavedAlarms();
        return;
      }

      // 2️⃣ حفظ معرف المستخدم الحالي
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);

      // 3️⃣ حفظ المنبهات في SharedPreferences
      await saveMedicationAlarms(medications);

      // 4️⃣ جدولة المنبهات الجديدة
      int scheduledCount = 0;
      for (final medication in medications) {
        if (medication.isActive) {
          await AlarmService.scheduleAllAlarmsForMedication(medication);
          scheduledCount++;
        }
      }

      debugPrint('✅ Scheduled alarms for $scheduledCount medications (User: $userId)');
    } catch (e) {
      debugPrint('❌ Failed to schedule alarms for user: $e');
    }
  }

  /// إلغاء جميع المنبهات الموجودة (للمستخدم القديم)
  static Future<void> cancelAllExistingAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsData = prefs.getString(_alarmsKey);
      
      if (alarmsData == null || alarmsData.isEmpty) {
        debugPrint('ℹ️ No existing alarms to cancel');
        return;
      }

      // محاولة إلغاء المنبهات بناءً على البيانات المحفوظة
      // نستخدم نطاق واسع من IDs لضمان إلغاء جميع المنبهات
      debugPrint('🗑️ Cancelling all existing alarms...');
      
      // إلغاء نطاق واسع من IDs المحتملة
      for (int i = 0; i < 1000; i++) {
        try {
          await AlarmService.cancelAlarm(i);
        } catch (e) {
          // تجاهل الأخطاء - المنبه قد لا يكون موجوداً
        }
      }
      
      debugPrint('✅ Cancelled all existing alarms');
    } catch (e) {
      debugPrint('⚠️ Error cancelling existing alarms: $e');
    }
  }

  /// إعادة جدولة المنبهات عند بدء التطبيق
  static Future<void> rescheduleAlarmsOnStartup() async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        // التحقق من تغيير المستخدم
        final prefs = await SharedPreferences.getInstance();
        final savedUserId = prefs.getString('current_user_id');
        
        if (savedUserId != null && savedUserId != currentUser.uid) {
          debugPrint('⚠️ User changed! Old: $savedUserId, New: ${currentUser.uid}');
          debugPrint('🔄 Cancelling old user alarms and scheduling new ones');
          await cancelAllExistingAlarms();
        }
        
        debugPrint('👤 User logged in - rescheduling alarms');
        await scheduleAllAlarmsForUser(currentUser.uid);
      } else {
        debugPrint('⚠️ No user logged in - alarms will not be scheduled');
        // إلغاء أي منبهات موجودة
        await cancelAllExistingAlarms();
        await clearSavedAlarms();
      }
    } catch (e) {
      debugPrint('❌ Failed to reschedule alarms on startup: $e');
    }
  }

  /// التحقق من المنبهات وإعادة جدولتها إذا لزم الأمر
  static Future<void> checkAndRescheduleAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceSync = (now - lastSync) / (1000 * 60 * 60);

      // إذا مر أكثر من 12 ساعة، أعد الجدولة
      if (hoursSinceSync > 12) {
        debugPrint('⏰ More than 12 hours since last sync - rescheduling');
        await rescheduleAlarmsOnStartup();
      } else {
        debugPrint('✅ Alarms are up to date');
      }
    } catch (e) {
      debugPrint('❌ Failed to check alarms: $e');
    }
  }

  /// مسح المنبهات المحفوظة (عند حذف جميع الأدوية أو تسجيل الخروج)
  static Future<void> clearSavedAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_alarmsKey);
      await prefs.remove(_lastSyncKey);
      await prefs.remove('current_user_id');
      debugPrint('🗑️ Cleared saved alarms');
    } catch (e) {
      debugPrint('❌ Failed to clear saved alarms: $e');
    }
  }

  /// إلغاء جميع المنبهات عند تسجيل الخروج
  static Future<void> cancelAlarmsOnLogout() async {
    try {
      debugPrint('🚪 User logging out - cancelling all alarms');
      await cancelAllExistingAlarms();
      await clearSavedAlarms();
      debugPrint('✅ All alarms cancelled and data cleared on logout');
    } catch (e) {
      debugPrint('❌ Failed to cancel alarms on logout: $e');
    }
  }

  /// الحصول على عدد المنبهات المحفوظة
  static Future<int> getSavedAlarmsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsData = prefs.getString(_alarmsKey);
      if (alarmsData == null) return 0;
      // هذا تقدير تقريبي - يمكن تحسينه
      return alarmsData.split('id:').length - 1;
    } catch (e) {
      return 0;
    }
  }
}
