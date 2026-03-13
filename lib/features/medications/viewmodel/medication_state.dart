import 'package:equatable/equatable.dart';
import '../model/medication_model.dart';
import '../model/medication_log_model.dart';

/// بيانات جرعة الدواء
class MedicationDose {
  final MedicationModel medication;
  final String time;
  final MedicationLogStatus? status;
  final DateTime? takenAt;

  MedicationDose({
    required this.medication,
    required this.time,
    this.status,
    this.takenAt,
  });

  bool get isTaken => status == MedicationLogStatus.taken;
  bool get isSkipped => status == MedicationLogStatus.skipped;
  bool get isPending => status == null;
}

/// مجموعة الجدول الزمني
class ScheduleGroup {
  final String period;
  final String time;
  final List<MedicationDose> doses;

  ScheduleGroup({
    required this.period,
    required this.time,
    required this.doses,
  });

  int get pendingCount => doses.where((d) => d.isPending).length;
  int get takenCount => doses.where((d) => d.isTaken).length;
  bool get isAllDone => pendingCount == 0;
}

/// الحالات الأساسية
abstract class MedicationState extends Equatable {
  const MedicationState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class MedicationInitial extends MedicationState {}

/// حالة التحميل
class MedicationLoading extends MedicationState {}

/// حالة تحميل الأدوية بنجاح
class MedicationLoaded extends MedicationState {
  final List<MedicationModel> medications;
  final List<ScheduleGroup> todaySchedule;
  final List<MedicationLogModel> todayLogs;

  const MedicationLoaded({
    this.medications = const [],
    this.todaySchedule = const [],
    this.todayLogs = const [],
  });

  /// عدد الأدوية المعلقة اليوم
  int get pendingDosesCount {
    int count = 0;
    for (final group in todaySchedule) {
      count += group.pendingCount;
    }
    return count;
  }

  /// عدد الأدوية المأخوذة اليوم
  int get takenDosesCount {
    int count = 0;
    for (final group in todaySchedule) {
      count += group.takenCount;
    }
    return count;
  }

  /// نسبة الالتزام اليوم
  double get todayComplianceRate {
    final total = pendingDosesCount + takenDosesCount;
    if (total == 0) return 1.0;
    return takenDosesCount / total;
  }

  @override
  List<Object?> get props => [medications, todaySchedule, todayLogs];
}

/// حالة لا توجد أدوية
class MedicationEmpty extends MedicationState {}

/// حالة الخطأ
class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة إضافة دواء بنجاح
class MedicationAdded extends MedicationState {}

/// حالة حذف دواء بنجاح
class MedicationDeleted extends MedicationState {}

/// حالة تناول جرعة بنجاح
class MedicationDoseTaken extends MedicationState {
  final String medicationName;

  const MedicationDoseTaken(this.medicationName);

  @override
  List<Object?> get props => [medicationName];
}

/// حالة تخطي جرعة
class MedicationDoseSkipped extends MedicationState {
  final String medicationName;

  const MedicationDoseSkipped(this.medicationName);

  @override
  List<Object?> get props => [medicationName];
}

/// حالة تحديث دواء بنجاح
class MedicationUpdated extends MedicationState {}

/// حالة حذف أدوية متعددة بنجاح
class MedicationsDeleted extends MedicationState {
  final int count;

  const MedicationsDeleted(this.count);

  @override
  List<Object?> get props => [count];
}
