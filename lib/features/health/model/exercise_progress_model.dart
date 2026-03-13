import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج تتبع تقدم التمارين
class ExerciseProgressModel {
  final String id;
  final String userId;
  final String exerciseId;
  final DateTime completedAt;
  final int durationSeconds;
  final int pointsEarned;

  ExerciseProgressModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.completedAt,
    required this.durationSeconds,
    required this.pointsEarned,
  });

  factory ExerciseProgressModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExerciseProgressModel(
      id: docId,
      userId: map['userId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      durationSeconds: map['durationSeconds'] ?? 0,
      pointsEarned: map['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'completedAt': Timestamp.fromDate(completedAt),
      'durationSeconds': durationSeconds,
      'pointsEarned': pointsEarned,
    };
  }
}

/// إحصائيات المستخدم
class UserExerciseStats {
  final int totalPoints;
  final int totalExercisesCompleted;
  final int totalTimeSeconds;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastExerciseDate;
  final Map<String, int> exerciseTypeCount; // breathing: 5, stretching: 3, etc.

  const UserExerciseStats({
    this.totalPoints = 0,
    this.totalExercisesCompleted = 0,
    this.totalTimeSeconds = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastExerciseDate,
    this.exerciseTypeCount = const {},
  });

  factory UserExerciseStats.fromMap(Map<String, dynamic> map) {
    return UserExerciseStats(
      totalPoints: map['totalPoints'] ?? 0,
      totalExercisesCompleted: map['totalExercisesCompleted'] ?? 0,
      totalTimeSeconds: map['totalTimeSeconds'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastExerciseDate: map['lastExerciseDate'] != null
          ? (map['lastExerciseDate'] as Timestamp).toDate()
          : null,
      exerciseTypeCount: map['exerciseTypeCount'] != null
          ? Map<String, int>.from(map['exerciseTypeCount'])
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPoints': totalPoints,
      'totalExercisesCompleted': totalExercisesCompleted,
      'totalTimeSeconds': totalTimeSeconds,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastExerciseDate': lastExerciseDate != null
          ? Timestamp.fromDate(lastExerciseDate!)
          : null,
      'exerciseTypeCount': exerciseTypeCount,
    };
  }

  UserExerciseStats copyWith({
    int? totalPoints,
    int? totalExercisesCompleted,
    int? totalTimeSeconds,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastExerciseDate,
    Map<String, int>? exerciseTypeCount,
  }) {
    return UserExerciseStats(
      totalPoints: totalPoints ?? this.totalPoints,
      totalExercisesCompleted: totalExercisesCompleted ?? this.totalExercisesCompleted,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastExerciseDate: lastExerciseDate ?? this.lastExerciseDate,
      exerciseTypeCount: exerciseTypeCount ?? this.exerciseTypeCount,
    );
  }

  String getFormattedTotalTime() {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// نظام النقاط
class ExercisePointsSystem {
  // نقاط حسب نوع التمرين
  static int getPointsForExercise(String exerciseType, int durationSeconds) {
    final basePoints = _getBasePoints(exerciseType);
    final durationBonus = (durationSeconds / 60).ceil(); // نقطة إضافية لكل دقيقة
    return basePoints + durationBonus;
  }

  static int _getBasePoints(String exerciseType) {
    switch (exerciseType) {
      case 'breathing':
        return 10;
      case 'stretching':
        return 15;
      case 'meditation':
        return 20;
      case 'yoga':
        return 25;
      default:
        return 10;
    }
  }

  // مستويات بناءً على النقاط
  static int getLevelFromPoints(int points) {
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    if (points < 1500) return 5;
    if (points < 2100) return 6;
    if (points < 2800) return 7;
    if (points < 3600) return 8;
    if (points < 4500) return 9;
    return 10;
  }

  static int getPointsNeededForNextLevel(int currentPoints) {
    final currentLevel = getLevelFromPoints(currentPoints);
    final nextLevelThresholds = [100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 5500];
    
    if (currentLevel >= 10) return 0;
    return nextLevelThresholds[currentLevel] - currentPoints;
  }
}
