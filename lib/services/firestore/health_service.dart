import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/health/model/heart_rate_model.dart';
import '../../features/health/model/exercise_model.dart';
import '../../features/health/model/exercise_progress_model.dart';

class HealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== HEART RATE ==========

  // Collection path: users/{userId}/heart_rate_logs
  CollectionReference _getHeartRateCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('heart_rate_logs');
  }

  // حفظ قياس ضربات القلب
  Future<HeartRateModel> saveHeartRate({
    required String visitorId,
    required int bpm,
    String? notes,
  }) async {
    try {
      final model = HeartRateModel(
        id: '',
        visitorId: visitorId,
        bpm: bpm,
        category: HeartRateModel.categorizeFromBpm(bpm),
        measuredAt: DateTime.now(),
        notes: notes,
      );

      final docRef = await _getHeartRateCollection(visitorId).add(model.toMap());

      return HeartRateModel(
        id: docRef.id,
        visitorId: visitorId,
        bpm: bpm,
        category: model.category,
        measuredAt: model.measuredAt,
        notes: notes,
      );
    } catch (e) {
      throw Exception('Failed to save heart rate: $e');
    }
  }

  // الحصول على آخر قياس
  Future<HeartRateModel?> getLastHeartRate(String userId) async {
    try {
      final snapshot = await _getHeartRateCollection(userId)
          .orderBy('measuredAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return HeartRateModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Failed to get last heart rate: $e');
    }
  }

  // الحصول على سجل القياسات
  Future<List<HeartRateModel>> getHeartRateHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _getHeartRateCollection(userId)
          .orderBy('measuredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => HeartRateModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get heart rate history: $e');
    }
  }

  // الحصول على قياسات اليوم
  Future<List<HeartRateModel>> getTodayHeartRates(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _getHeartRateCollection(userId)
          .where('measuredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('measuredAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('measuredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HeartRateModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get today heart rates: $e');
    }
  }

  // ========== EXERCISES ==========

  // الحصول على تمارين التمدد
  Future<List<ExerciseModel>> getStretchingExercises() async {
    try {
      final snapshot = await _firestore
          .collection('exercises')
          .where('type', isEqualTo: 'stretching')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stretching exercises: $e');
    }
  }

  // الحصول على تمارين التنفس
  Future<List<ExerciseModel>> getBreathingExercises() async {
    try {
      final snapshot = await _firestore
          .collection('exercises')
          .where('type', isEqualTo: 'breathing')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get breathing exercises: $e');
    }
  }

  // تحديث مستوى الطوارئ
  Future<void> updateEmergencyLevel(String userId, int level) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'emergencyLevel': level,
        'emergencyLevelUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update emergency level: $e');
    }
  }

  // الحصول على مستوى الطوارئ
  Future<int?> getEmergencyLevel(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('emergencyLevel')) {
        return doc.data()!['emergencyLevel'] as int;
      }
      return null;
    } catch (e) {
      // إذا فشل، نعود للقيمة المحسوبة
      return null;
    }
  }

  // الحصول على التمارين بناءً على النوع
  Future<List<ExerciseModel>> getExercisesByType(String type) async {
    try {
      final snapshot = await _firestore
          .collection('exercises')
          .where('type', isEqualTo: type)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exercises by type: $e');
    }
  }

  // الحصول على جميع التمارين
  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      final snapshot = await _firestore
          .collection('exercises')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exercises: $e');
    }
  }

  // ========== EXERCISE PROGRESS & STATS ==========

  // حفظ تقدم التمرين
  Future<void> saveExerciseProgress({
    required String userId,
    required String exerciseId,
    required int durationSeconds,
    required int pointsEarned,
    required String exerciseType,
  }) async {
    try {
      final progress = ExerciseProgressModel(
        id: '',
        userId: userId,
        exerciseId: exerciseId,
        completedAt: DateTime.now(),
        durationSeconds: durationSeconds,
        pointsEarned: pointsEarned,
      );

      // حفظ السجل
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercise_progress')
          .add(progress.toMap());

      // تحديث الإحصائيات
      await _updateUserStats(userId, exerciseType, durationSeconds, pointsEarned);
    } catch (e) {
      throw Exception('Failed to save exercise progress: $e');
    }
  }

  // تحديث إحصائيات المستخدم
  Future<void> _updateUserStats(
    String userId,
    String exerciseType,
    int durationSeconds,
    int pointsEarned,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final statsDoc = await userDoc.get();

    UserExerciseStats currentStats;
    if (statsDoc.exists && statsDoc.data()!.containsKey('exerciseStats')) {
      currentStats = UserExerciseStats.fromMap(statsDoc.data()!['exerciseStats']);
    } else {
      currentStats = UserExerciseStats();
    }

    // تحديث العدادات
    final newTypeCount = Map<String, int>.from(currentStats.exerciseTypeCount);
    newTypeCount[exerciseType] = (newTypeCount[exerciseType] ?? 0) + 1;

    // حساب السلسلة (streak)
    final now = DateTime.now();
    final lastDate = currentStats.lastExerciseDate;
    int newStreak = currentStats.currentStreak;

    if (lastDate != null) {
      final daysDiff = now.difference(lastDate).inDays;
      if (daysDiff == 0) {
        // نفس اليوم - لا تغيير
      } else if (daysDiff == 1) {
        // يوم متتالي
        newStreak++;
      } else {
        // انقطعت السلسلة
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newStats = currentStats.copyWith(
      totalPoints: currentStats.totalPoints + pointsEarned,
      totalExercisesCompleted: currentStats.totalExercisesCompleted + 1,
      totalTimeSeconds: currentStats.totalTimeSeconds + durationSeconds,
      currentStreak: newStreak,
      longestStreak: newStreak > currentStats.longestStreak
          ? newStreak
          : currentStats.longestStreak,
      lastExerciseDate: now,
      exerciseTypeCount: newTypeCount,
    );

    await userDoc.update({'exerciseStats': newStats.toMap()});
  }

  // الحصول على إحصائيات المستخدم
  Future<UserExerciseStats> getUserExerciseStats(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists && doc.data()!.containsKey('exerciseStats')) {
        return UserExerciseStats.fromMap(doc.data()!['exerciseStats']);
      }
      
      return UserExerciseStats();
    } catch (e) {
      return UserExerciseStats();
    }
  }

  // الحصول على سجل التمارين
  Future<List<ExerciseProgressModel>> getExerciseHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercise_progress')
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ExerciseProgressModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exercise history: $e');
    }
  }

  // الحصول على تمارين اليوم
  Future<List<ExerciseProgressModel>> getTodayExercises(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercise_progress')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExerciseProgressModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get today exercises: $e');
    }
  }
}
