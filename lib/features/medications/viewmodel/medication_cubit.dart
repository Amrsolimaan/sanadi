import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanadi/services/firestore/alarm_service.dart';
import 'package:sanadi/services/firestore/persistent_alarm_service.dart';
import 'medication_state.dart';
import '../model/medication_model.dart';
import '../../../services/firestore/medication_service.dart';

class MedicationCubit extends Cubit<MedicationState> {
  MedicationCubit() : super(MedicationInitial());

  final MedicationService _service = MedicationService();

  /// تحميل الأدوية
  Future<void> loadMedications() async {
    emit(MedicationLoading());

    try {
      final medications = await _service.getMedications();

      if (medications.isEmpty) {
        emit(MedicationEmpty());
        return;
      }

      final todayMedications = await _service.getTodayMedications();
      final todayLogs = await _service.getTodayLogs();
      final schedule = _buildSchedule(todayMedications, todayLogs);

      emit(MedicationLoaded(
        medications: medications,
        todaySchedule: schedule,
        todayLogs: todayLogs,
      ));
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  /// بناء جدول اليوم
  List<ScheduleGroup> _buildSchedule(
      List<MedicationModel> medications, List<dynamic> logs) {
    final Map<String, List<MedicationDose>> timeGroups = {};

    for (final med in medications) {
      for (final time in med.times) {
        timeGroups.putIfAbsent(time, () => []);

        final log = logs
            .cast<dynamic>()
            .where(
              (l) => l.medicationId == med.id && l.scheduledTime == time,
            )
            .firstOrNull;

        timeGroups[time]!.add(MedicationDose(
          medication: med,
          time: time,
          status: log?.status,
          takenAt: log?.takenAt,
        ));
      }
    }

    final sortedTimes = timeGroups.keys.toList()..sort();
    return sortedTimes
        .map((time) => ScheduleGroup(
              period: _getPeriod(time),
              time: time,
              doses: timeGroups[time]!,
            ))
        .toList();
  }

  /// تحديد فترة اليوم
  String _getPeriod(String time) {
    final hour = int.tryParse(time.split(':')[0]) ?? 0;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// إضافة دواء جديد
  Future<void> addMedication(MedicationModel medication) async {
    try {
      // إضافة للفايربيز
      final docId = await _service.addMedication(medication);

      // إنشاء نسخة بالـ ID الجديد
      final newMedication = MedicationModel(
        id: docId,
        visitorId: medication.visitorId,
        name: medication.name,
        nameAr: medication.nameAr,
        dose: medication.dose,
        type: medication.type,
        purpose: medication.purpose,
        purposeAr: medication.purposeAr,
        frequency: medication.frequency,
        specificDays: medication.specificDays,
        times: medication.times,
        isActive: medication.isActive,
        createdAt: medication.createdAt,
      );

      // جدولة المنبهات
      await AlarmService.scheduleAllAlarmsForMedication(newMedication);
      
      // حفظ المنبهات في التخزين المحلي
      final medications = await _service.getMedications();
      await PersistentAlarmService.saveMedicationAlarms(medications);

      emit(MedicationAdded());
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  /// تسجيل تناول الدواء
  Future<void> markAsTaken(
      String medicationId, String time, String name) async {
    try {
      await _service.logMedicationTaken(medicationId, time, name);
      emit(MedicationDoseTaken(name));
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  /// تسجيل تخطي الدواء
  Future<void> markAsSkipped(
      String medicationId, String time, String name) async {
    try {
      await _service.logMedicationSkipped(medicationId, time, name);
      emit(MedicationDoseSkipped(name));
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  /// حذف دواء
  Future<void> deleteMedication(String id) async {
    try {
      // الحصول على الدواء قبل الحذف
      final medications = await _service.getMedications();
      final medication = medications.firstWhere(
        (m) => m.id == id,
        orElse: () => throw Exception('Medication not found'),
      );

      // إلغاء المنبهات
      await AlarmService.cancelMedicationAlarms(medication);

      // حذف من الفايربيز
      await _service.deleteMedication(id);

      emit(MedicationDeleted());
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  /// حذف أدوية متعددة
  Future<void> deleteMultipleMedications(List<String> ids) async {
    try {
      final medications = await _service.getMedications();

      for (final id in ids) {
        final medication = medications.firstWhere(
          (m) => m.id == id,
          orElse: () => throw Exception('Medication not found'),
        );

        // إلغاء المنبهات
        await AlarmService.cancelMedicationAlarms(medication);

        // حذف من الفايربيز
        await _service.deleteMedication(id);
      }

      emit(MedicationsDeleted(ids.length));
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  /// تحديث دواء
  Future<void> updateMedication(MedicationModel medication) async {
    try {
      // إلغاء المنبهات القديمة
      await AlarmService.cancelMedicationAlarms(medication);

      // تحديث في الفايربيز
      await _service.updateMedication(medication.id, medication);

      // جدولة المنبهات الجديدة
      if (medication.isActive) {
        await AlarmService.scheduleAllAlarmsForMedication(medication);
      }
      
      // حفظ المنبهات في التخزين المحلي
      final medications = await _service.getMedications();
      await PersistentAlarmService.saveMedicationAlarms(medications);

      emit(MedicationUpdated());
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  /// الحصول على أيقونة الفترة
  String getPeriodIcon(String period) {
    switch (period) {
      case 'morning':
        return '☀️';
      case 'afternoon':
        return '🌤️';
      case 'evening':
        return '🌅';
      case 'night':
        return '🌙';
      default:
        return '⏰';
    }
  }

  /// الحصول على اسم الفترة
  String getPeriodName(String period, String lang) {
    final names = {
      'morning': lang == 'ar' ? 'الصباح' : 'Morning',
      'afternoon': lang == 'ar' ? 'الظهر' : 'Afternoon',
      'evening': lang == 'ar' ? 'المساء' : 'Evening',
      'night': lang == 'ar' ? 'الليل' : 'Night',
    };
    return names[period] ?? period;
  }

  /// إعادة جدولة جميع المنبهات (مفيد عند إعادة التشغيل)
  Future<void> rescheduleAllAlarms() async {
    try {
      final medications = await _service.getMedications();
      for (final medication in medications) {
        if (medication.isActive) {
          await AlarmService.scheduleAllAlarmsForMedication(medication);
        }
      }
    } catch (e) {
      emit(MedicationError('Failed to reschedule alarms: $e'));
    }
  }

  /// مسح البيانات (عند تسجيل الخروج)
  void clear() {
    emit(MedicationInitial());
  }
}
