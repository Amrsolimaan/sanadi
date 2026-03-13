import 'package:equatable/equatable.dart';
import '../model/heart_rate_model.dart';
import '../model/exercise_model.dart';
import '../model/exercise_progress_model.dart';

abstract class HealthState extends Equatable {
  const HealthState();

  @override
  List<Object?> get props => [];
}

// ========== حالات عامة ==========

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthLoaded extends HealthState {
  final HeartRateModel? lastHeartRate;
  final List<HeartRateModel> heartRateHistory;
  final int emergencyLevel;
  final List<String> completedExerciseIds;
  final List<ExerciseModel> exercises;
  final UserExerciseStats userStats;

  const HealthLoaded({
    this.lastHeartRate,
    required this.heartRateHistory,
    required this.emergencyLevel,
    required this.exercises,
    this.completedExerciseIds = const [],
    UserExerciseStats? userStats,
  }) : userStats = userStats ?? const UserExerciseStats();

  @override
  List<Object?> get props => [
        lastHeartRate,
        heartRateHistory,
        emergencyLevel,
        exercises,
        completedExerciseIds,
        userStats,
      ];

  HealthLoaded copyWith({
    HeartRateModel? lastHeartRate,
    List<HeartRateModel>? heartRateHistory,
    int? emergencyLevel,
    List<ExerciseModel>? exercises,
    List<String>? completedExerciseIds,
    UserExerciseStats? userStats,
  }) {
    return HealthLoaded(
      lastHeartRate: lastHeartRate ?? this.lastHeartRate,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
      emergencyLevel: emergencyLevel ?? this.emergencyLevel,
      exercises: exercises ?? this.exercises,
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      userStats: userStats ?? this.userStats,
    );
  }
}

class HealthError extends HealthState {
  final String message;

  const HealthError({required this.message});

  @override
  List<Object> get props => [message];
}

// ========== حالات قياس ضربات القلب ==========

/// ⭐ حالة جديدة: التوجيه أثناء الإعداد
class HeartRateMeasureGuiding extends HealthState {
  final String message;

  const HeartRateMeasureGuiding({required this.message});

  @override
  List<Object> get props => [message];
}

/// جاهز لبدء القياس
class HeartRateMeasureReady extends HealthState {}

/// جاري القياس
class HeartRateMeasuring extends HealthState {
  final int progress; // 0-100
  final List<double> readings;
  final String? message; // ⭐ رسالة اختيارية

  const HeartRateMeasuring({
    required this.progress,
    required this.readings,
    this.message,
  });

  @override
  List<Object?> get props => [progress, readings, message];
}

/// اكتمل القياس
class HeartRateMeasureComplete extends HealthState {
  final int bpm;
  final String category;
  final double? signalQuality; // ⭐ جودة الإشارة

  const HeartRateMeasureComplete({
    required this.bpm,
    required this.category,
    this.signalQuality,
  });

  @override
  List<Object?> get props => [bpm, category, signalQuality];
}

/// خطأ في القياس
class HeartRateMeasureError extends HealthState {
  final String message;

  const HeartRateMeasureError({required this.message});

  @override
  List<Object> get props => [message];
}

/// تم حفظ القياس
class HeartRateSaved extends HealthState {
  final HeartRateModel heartRate;

  const HeartRateSaved({required this.heartRate});

  @override
  List<Object> get props => [heartRate];
}
