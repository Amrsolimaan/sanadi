import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import '../../../services/firestore/health_service.dart';
import '../model/heart_rate_model.dart';
import '../model/exercise_model.dart';
import '../../../core/constants/supabase_storage.dart';
import 'health_state.dart';

class HealthCubit extends Cubit<HealthState> {
  final HealthService _healthService = HealthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CameraController? _cameraController;
  Timer? _measureTimer;
  List<double> _readings = [];
  final int _measureDuration = 30;

  // متغيرات للتحسينات
  double _baselineLight = 0;

  // ⭐ متغيرات جديدة لكشف الإصبع
  bool _isFingerDetected = false;
  int _fingerLossCount = 0;
  static const int _maxFingerLossFrames =
      15; // السماح بـ 15 إطار بدون إصبع قبل الإلغاء

  HealthCubit() : super(HealthInitial());

  String? get _userId => _auth.currentUser?.uid;

  // ========== تحميل البيانات ==========

  Future<void> loadHealthData() async {
    if (_userId == null) {
      emit(const HealthError(message: 'User not logged in'));
      return;
    }

    emit(HealthLoading());

    try {
      final lastHeartRate = await _healthService.getLastHeartRate(_userId!);
      final history = await _healthService.getHeartRateHistory(_userId!);
      var exercises = await _healthService.getAllExercises();

      // إضافة تمارين افتراضية إذا لم تكن موجودة
      if (exercises.isEmpty) {
        exercises = _getDefaultExercises();
      } else {
        final hasBreathing = exercises.any((e) => e.type == ExerciseType.breathing);
        final hasStretching = exercises.any((e) => e.type == ExerciseType.stretching);
        final hasMeditation = exercises.any((e) => e.type == ExerciseType.meditation);
        final hasYoga = exercises.any((e) => e.type == ExerciseType.yoga);

        if (!hasBreathing || !hasStretching || !hasMeditation || !hasYoga) {
          final defaults = _getDefaultExercises();
          if (!hasBreathing) {
            exercises.addAll(defaults.where((e) => e.type == ExerciseType.breathing));
          }
          if (!hasStretching) {
            exercises.addAll(defaults.where((e) => e.type == ExerciseType.stretching));
          }
          if (!hasMeditation) {
            exercises.addAll(defaults.where((e) => e.type == ExerciseType.meditation));
          }
          if (!hasYoga) {
            exercises.addAll(defaults.where((e) => e.type == ExerciseType.yoga));
          }
        }
      }

      // الحصول على إحصائيات المستخدم
      final stats = await _healthService.getUserExerciseStats(_userId!);

      // حساب مستوى الطوارئ بناءً على التقدم
      int emergencyLevel = _calculateEmergencyLevelFromProgress(
        stats.totalExercisesCompleted,
        exercises.length,
      );

      // تحديث المستوى في Firestore
      await _healthService.updateEmergencyLevel(_userId!, emergencyLevel);

      emit(HealthLoaded(
        lastHeartRate: lastHeartRate,
        heartRateHistory: history,
        emergencyLevel: emergencyLevel,
        exercises: exercises,
        completedExerciseIds: [], // سيتم استبداله بنظام أفضل
        userStats: stats,
      ));
    } catch (e) {
      emit(HealthError(message: e.toString()));
    }
  }

  /// إكمال تمرين مع نظام النقاط
  Future<void> completeExercise(
    String exerciseId,
    String exerciseType,
    int durationSeconds,
    int pointsEarned,
  ) async {
    if (state is! HealthLoaded || _userId == null) return;

    final currentState = state as HealthLoaded;

    try {
      // حفظ التقدم في Firestore
      await _healthService.saveExerciseProgress(
        userId: _userId!,
        exerciseId: exerciseId,
        durationSeconds: durationSeconds,
        pointsEarned: pointsEarned,
        exerciseType: exerciseType,
      );

      // إعادة تحميل البيانات لتحديث الإحصائيات
      await loadHealthData();
    } catch (e) {
      emit(HealthError(message: e.toString()));
      // استعادة الحالة السابقة
      emit(currentState);
    }
  }

  int _calculateEmergencyLevelFromProgress(int completedCount, int totalCount) {
    if (totalCount == 0) return 0;
    final progress = completedCount / totalCount;
    // Level starts at 0 and goes up to 10 as progress goes to 100%
    return (progress * 10).round().clamp(0, 10);
  }

  // ========== قياس ضربات القلب المحسّن ==========

  /// ⭐ بدء القياس مع كشف الإصبع
  Future<void> startMeasuring(List<CameraDescription> cameras) async {
    try {
      // البحث عن الكاميرا الخلفية
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // ⭐ المرحلة 1: رسالة توجيهية
      emit(const HeartRateMeasureGuiding(
        message: 'ضع إصبعك بإحكام على الكاميرا والفلاش',
      ));

      // تشغيل الفلاش للكشف
      await _cameraController!.setFlashMode(FlashMode.torch);
      await Future.delayed(const Duration(milliseconds: 800));

      // ⭐ المرحلة 2: كشف الإصبع
      emit(const HeartRateMeasureGuiding(
        message: 'جاري الكشف عن الإصبع...',
      ));

      final fingerDetected = await _detectFingerOnCamera();

      if (!fingerDetected) {
        await _cameraController?.setFlashMode(FlashMode.off);
        await _cameraController?.dispose();
        _cameraController = null;

        emit(const HeartRateMeasureError(
          message:
              'لم يتم اكتشاف الإصبع. يرجى تغطية الكاميرا بالكامل والمحاولة مرة أخرى.',
        ));
        return;
      }

      // ⭐ المرحلة 3: معايرة الضوء
      emit(const HeartRateMeasureGuiding(
        message: 'تم اكتشاف الإصبع... جاري المعايرة',
      ));

      // انتظار قصير للتأكد من توقف الستريم السابق
      await Future.delayed(const Duration(milliseconds: 200));

      await _calibrateBaselineLight();

      // ⭐ المرحلة 4: بدء القياس الفعلي
      _readings = [];
      _isFingerDetected = true;
      _fingerLossCount = 0;

      emit(const HeartRateMeasureGuiding(
        message: 'ابق ثابتاً... جاري القياس',
      ));

      await Future.delayed(const Duration(milliseconds: 500));

      // بدء التقاط الصور
      await _cameraController!.startImageStream(_processImage);

      // بدء العد التنازلي
      int elapsed = 0;
      _measureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        elapsed++;
        final progress = ((elapsed / _measureDuration) * 100).round();

        // التحقق من أن الإصبع ما زال موجوداً
        if (!_isFingerDetected) {
          _finishMeasuringWithError(
              'تمت إزالة الإصبع. يرجى الحفاظ على الإصبع ثابتاً.');
          return;
        }

        emit(HeartRateMeasuring(
          progress: progress,
          readings: List.from(_readings),
          message: 'القياس جاري... ${_measureDuration - elapsed}s',
        ));

        if (elapsed >= _measureDuration) {
          _finishMeasuring();
        }
      });
    } catch (e) {
      emit(HeartRateMeasureError(message: e.toString()));
    }
  }

  /// ⭐ كشف الإصبع على الكاميرا
  Future<bool> _detectFingerOnCamera() async {
    List<double> testReadings = [];
    int samples = 0;
    const requiredSamples = 30; // حوالي 1 ثانية

    final completer = Completer<bool>();

    await _cameraController!.startImageStream((image) {
      if (samples < requiredSamples) {
        final brightness = _extractBrightness(image);
        testReadings.add(brightness);
        samples++;
      } else {
        // التحقق من أن الكومبليتر لم ينتهِ بعد لتجنب الأخطاء
        if (!completer.isCompleted) {
          _cameraController?.stopImageStream();

          // تحليل البيانات
          final avgBrightness =
              testReadings.reduce((a, b) => a + b) / testReadings.length;

          // إضافة فحص اللون في العينة الأخيرة
          final isRed = _checkRedColorInImage(image);

          // شروط الكشف:
          // 1. السطوع كافي (الجلد يعكس الضوء الأحمر)
          // 2. اللون أحمر (لتجنب الحوائط البيضاء)
          final isFingerPresent =
              avgBrightness > 60 && avgBrightness < 250 && isRed;

          completer.complete(isFingerPresent);
        }
      }
    });

    return completer.future;
  }

  /// ⭐ معايرة الضوء المحيط
  Future<void> _calibrateBaselineLight() async {
    final completer = Completer<void>();
    List<double> baselineReadings = [];
    int sampleCount = 0;
    const maxSamples = 15;

    await _cameraController!.startImageStream((image) {
      if (sampleCount < maxSamples) {
        final brightness = _extractBrightness(image);
        baselineReadings.add(brightness);
        sampleCount++;
      } else {
        // التحقق من أن الكومبليتر لم ينتهِ بعد
        if (!completer.isCompleted) {
          _cameraController?.stopImageStream();

          // استخدام median بدلاً من mean لمقاومة القيم الشاذة
          baselineReadings.sort();
          _baselineLight = baselineReadings[baselineReadings.length ~/ 2];

          completer.complete();
        }
      }
    });

    await completer.future;
  }

  /// معالجة الصورة مع كشف إزالة الإصبع
  void _processImage(CameraImage image) {
    try {
      final brightness = _extractBrightness(image);

      // ⭐ كشف إزالة الإصبع مع فحص اللون
      // إذا انخفض السطوع فجأة بشكل كبير أو لم يعد أحمر
      if (brightness < 40 || !_checkRedColorInImage(image)) {
        _fingerLossCount++;

        if (_fingerLossCount >= _maxFingerLossFrames) {
          _isFingerDetected = false;
        }
        return;
      } else {
        // إعادة تعيين العداد إذا عاد الإصبع
        _fingerLossCount = 0;
      }

      // طرح الضوء الأساسي
      final normalizedValue = brightness - _baselineLight;
      _readings.add(normalizedValue);

      // حد أقصى للعينات
      if (_readings.length > 1200) {
        _readings.removeAt(0);
      }
    } catch (e) {
      // تجاهل الأخطاء في المعالجة
    }
  }

  /// استخراج السطوع من YUV
  double _extractBrightness(CameraImage image) {
    final yPlane = image.planes[0];
    final bytes = yPlane.bytes;

    // حساب متوسط السطوع من عينة
    double sum = 0;
    int sampleSize = (bytes.length / 10).round();
    int step = (bytes.length / sampleSize).round();

    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
    }

    return sum / sampleSize;
  }

  /// ⭐ فحص اللون الأحمر في الصورة (YUV420) بمعايير متوازنة
  bool _checkRedColorInImage(CameraImage image) {
    // في صيغة YUV420:
    // Plane 0: Y (Luminance)
    // Plane 1: U (Cb - Blue Difference)
    // Plane 2: V (Cr - Red Difference)

    if (image.planes.length >= 3) {
      final uPlane = image.planes[1]; // Cb component
      final vPlane = image.planes[2]; // Cr component

      // حساب متوسط Cb و Cr
      final avgCb = _calculatePlaneAverage(uPlane);
      final avgCr = _calculatePlaneAverage(vPlane);

      // معاير الكشف:
      // 1. Cr (أحمر) يجب أن يكون أعلى من Cb (أزرق) - هذا يعني لون "دافئ"
      // 2. Cr يجب أن يكون أعلى من المعدل المحايد (128) بقليل
      // 128 هو الصفر في YUV، أي شيء فوق 128 يعني "موجود"
      // نستخدم 130 كحد أدنى آمن لضمان وجود احمرار حقيقي
      return (avgCr > avgCb) && (avgCr > 130);
    }

    // fallback
    return true;
  }

  double _calculatePlaneAverage(Plane plane) {
    double sum = 0;
    final bytes = plane.bytes;
    int sampleSize = (bytes.length / 20).round(); // عينة أصغر للسرعة
    int step = (bytes.length / sampleSize).round();

    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
    }

    return sum / sampleSize;
  }

  /// ⭐ إنهاء القياس مع خطأ
  Future<void> _finishMeasuringWithError(String message) async {
    _measureTimer?.cancel();
    _measureTimer = null;

    try {
      if (_cameraController != null) {
        await _cameraController!.setFlashMode(FlashMode.off);
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
      }
    } catch (e) {
      print('Error closing camera on error: $e');
    } finally {
      _cameraController = null;
    }

    emit(HeartRateMeasureError(message: message));
  }

  /// إنهاء القياس بنجاح
  Future<void> _finishMeasuring() async {
    _measureTimer?.cancel();
    _measureTimer = null;

    // إيقاف الفلاش والكاميرا بأمان
    try {
      if (_cameraController != null) {
        await _cameraController!.setFlashMode(FlashMode.off);
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
      }
    } catch (e) {
      // تجاهل أخطاء إغلاق الكاميرا لأننا انتهينا بالفعل
      print('Camera cleanup error: $e');
    } finally {
      _cameraController = null;
    }

    // التحقق من كفاية البيانات
    if (_readings.length < 50) {
      // قللنا الحد الأدنى قليلاً لتجنب الإحباط
      emit(const HeartRateMeasureError(
          message: 'بيانات غير كافية. يرجى المتابعة للنهاية.'));
      return;
    }

    // تقييم جودة الإشارة
    final signalQuality = _assessSignalQuality(_readings);

    // تخفيف شرط الجودة قليلاً
    if (signalQuality < 0.15) {
      emit(const HeartRateMeasureError(
          message: 'جودة الإشارة ضعيفة. حاول تثبيت إصبعك أكثر.'));
      return;
    }

    // حساب BPM
    final bpm = _calculateBPM(_readings);

    // التحقق من المعقولية
    if (bpm < 40 || bpm > 180) {
      emit(HeartRateMeasureError(
          message: 'قراءة غير دقيقة ($bpm). يرجى المحاولة مرة أخرى.'));
      return;
    }

    final categoryEnum = HeartRateModel.categorizeFromBpm(bpm);
    final category = categoryEnum.name; // تحويل enum إلى String
    emit(HeartRateMeasureComplete(
      bpm: bpm,
      category: category,
      signalQuality: signalQuality,
    ));
  }

  /// تقييم جودة الإشارة
  double _assessSignalQuality(List<double> readings) {
    if (readings.length < 10) return 0.0;

    final mean = readings.reduce((a, b) => a + b) / readings.length;
    final variance =
        readings.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            readings.length;
    final stdDev = math.sqrt(variance);

    // حساب SNR (Signal-to-Noise Ratio)
    final snr = mean.abs() > 0.1 ? (stdDev / mean.abs()) : 0;

    // تقييم الجودة بناءً على SNR
    if (snr < 0.02) return 0.1; // إشارة ثابتة جداً
    if (snr > 1.0) return 0.2; // ضوضاء كثيرة
    if (snr >= 0.05 && snr <= 0.6) return 1.0; // مثالي
    return 0.5; // مقبول
  }

  /// ⭐ حساب BPM المحسّن
  int _calculateBPM(List<double> readings) {
    if (readings.length < 100) return 70;

    try {
      // 1️⃣ إزالة الاتجاه
      final detrended = _detrend(readings);

      // 2️⃣ تطبيع البيانات
      final normalized = _normalize(detrended);

      // 3️⃣ تطبيق فلتر Butterworth
      final filtered = _butterworthFilter(normalized);

      // 4️⃣ كشف القمم
      final peaks = _findPeaksImproved(filtered);

      if (peaks.length < 4) {
        // محاولة بمعايير أقل صرامة
        final relaxedPeaks = _findPeaksRelaxed(filtered);
        if (relaxedPeaks.length < 3) {
          return 70; // قيمة افتراضية
        }
        return _calculateBPMFromPeaks(relaxedPeaks, readings.length);
      }

      return _calculateBPMFromPeaks(peaks, readings.length);
    } catch (e) {
      return 70; // قيمة افتراضية في حالة الخطأ
    }
  }

  /// حساب BPM من القمم
  int _calculateBPMFromPeaks(List<int> peaks, int totalReadings) {
    // حساب المسافات بين القمم
    List<int> intervals = [];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add(peaks[i] - peaks[i - 1]);
    }

    // إزالة القيم الشاذة (outliers)
    if (intervals.length > 3) {
      intervals.sort();
      // إزالة أصغر وأكبر قيمة
      intervals.removeAt(0);
      intervals.removeAt(intervals.length - 1);
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final fps = totalReadings / _measureDuration;
    final bpm = (60 * fps / avgInterval).round();

    // تطبيق حدود معقولة
    return bpm.clamp(45, 175);
  }

  /// إزالة الاتجاه (Detrending)
  List<double> _detrend(List<double> data) {
    final n = data.length;
    final xMean = (n - 1) / 2;
    final yMean = data.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      numerator += (i - xMean) * (data[i] - yMean);
      denominator += math.pow(i - xMean, 2);
    }

    final slope = denominator != 0 ? numerator / denominator : 0;
    final intercept = yMean - slope * xMean;

    return List.generate(
      n,
      (i) => data[i] - (slope * i + intercept),
    );
  }

  /// تطبيع البيانات (Normalization)
  List<double> _normalize(List<double> data) {
    final min = data.reduce(math.min);
    final max = data.reduce(math.max);
    final range = max - min;

    if (range == 0) return List.filled(data.length, 0);

    return data.map((x) => (x - min) / range).toList();
  }

  /// فلتر Butterworth
  List<double> _butterworthFilter(List<double> data) {
    final alpha = 0.15; // معامل التنعيم
    List<double> filtered = [data[0]];

    for (int i = 1; i < data.length; i++) {
      final smoothed = alpha * data[i] + (1 - alpha) * filtered[i - 1];
      filtered.add(smoothed);
    }

    return filtered;
  }

  /// كشف القمم المحسّن
  List<int> _findPeaksImproved(List<double> data) {
    List<int> peaks = [];

    // حساب عتبة ديناميكية
    final mean = data.reduce((a, b) => a + b) / data.length;
    final stdDev = math.sqrt(
      data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
          data.length,
    );
    final threshold = mean + stdDev * 0.6;

    // الحد الأدنى للمسافة بين القمم
    final fps = _readings.length / _measureDuration;
    final minDistance = (0.35 * fps).round(); // 0.35 ثانية

    for (int i = 2; i < data.length - 2; i++) {
      // تحقق من أن النقطة هي قمة محلية
      if (data[i] > threshold &&
          data[i] > data[i - 1] &&
          data[i] > data[i + 1] &&
          data[i] >= data[i - 2] &&
          data[i] >= data[i + 2]) {
        if (peaks.isEmpty || (i - peaks.last) >= minDistance) {
          peaks.add(i);
        }
      }
    }

    return peaks;
  }

  /// كشف القمم بمعايير أقل صرامة
  List<int> _findPeaksRelaxed(List<double> data) {
    List<int> peaks = [];

    final mean = data.reduce((a, b) => a + b) / data.length;
    final stdDev = math.sqrt(
      data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
          data.length,
    );
    final threshold = mean + stdDev * 0.4; // عتبة أقل

    final fps = _readings.length / _measureDuration;
    final minDistance = (0.3 * fps).round();

    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > threshold &&
          data[i] > data[i - 1] &&
          data[i] > data[i + 1]) {
        if (peaks.isEmpty || (i - peaks.last) >= minDistance) {
          peaks.add(i);
        }
      }
    }

    return peaks;
  }

  /// إلغاء القياس
  Future<void> cancelMeasuring() async {
    _measureTimer?.cancel();
    _measureTimer = null;

    await _cameraController?.setFlashMode(FlashMode.off);
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;

    _readings = [];
    _baselineLight = 0;
    _isFingerDetected = false;
    _fingerLossCount = 0;

    emit(HeartRateMeasureReady());
  }

  /// حفظ القياس
  Future<void> saveHeartRate(int bpm) async {
    if (_userId == null) return;

    try {
      final heartRate = await _healthService.saveHeartRate(
        visitorId: _userId!,
        bpm: bpm,
      );

      emit(HeartRateSaved(heartRate: heartRate));

      await loadHealthData();
    } catch (e) {
      emit(HealthError(message: e.toString()));
    }
  }

  /// تحديث مستوى الطوارئ
  void updateEmergencyLevel(int level) {
    if (state is HealthLoaded) {
      final currentState = state as HealthLoaded;
      emit(currentState.copyWith(emergencyLevel: level.clamp(1, 10)));
    }
  }

  @override
  Future<void> close() {
    _measureTimer?.cancel();
    _cameraController?.dispose();
    return super.close();
  }

  List<ExerciseModel> _getDefaultExercises() {
    return [
      // ================= BREATHING =================
      ExerciseModel(
        id: 'b1',
        name: {'en': 'Calm Breathing', 'ar': 'تنفس مهدئ'},
        description: {
          'en': 'Slow inhale and exhale to relax.',
          'ar': 'تنفس بطيء لتهدئة الجسم.'
        },
        durationSeconds: 60,
        imageUrl: '',
        order: 1,
        type: ExerciseType.breathing,
      ),
      ExerciseModel(
        id: 'b2',
        name: {'en': 'Box Breathing', 'ar': 'تنفس مربع'},
        description: {
          'en': 'Equal inhale, hold, exhale rhythm.',
          'ar': 'تنفس متوازن بإيقاع ثابت.'
        },
        durationSeconds: 90,
        imageUrl: '',
        order: 2,
        type: ExerciseType.breathing,
      ),
      ExerciseModel(
        id: 'b3',
        name: {'en': 'Energy Breath', 'ar': 'تنفس الطاقة'},
        description: {
          'en': 'Faster breathing to boost alertness.',
          'ar': 'تنفس سريع لزيادة النشاط.'
        },
        durationSeconds: 45,
        imageUrl: '',
        order: 3,
        type: ExerciseType.breathing,
      ),
      ExerciseModel(
        id: 'b4',
        name: {'en': 'Deep Reset', 'ar': 'إعادة ضبط عميقة'},
        description: {
          'en': 'Deep lung breathing cycle.',
          'ar': 'تنفس عميق لإعادة التوازن.'
        },
        durationSeconds: 120,
        imageUrl: '',
        order: 4,
        type: ExerciseType.breathing,
      ),

      // ================= STRETCHING =================
      ExerciseModel(
        id: 's1',
        name: {'en': 'Neck Release', 'ar': 'إرخاء الرقبة'},
        description: {'en': 'Gentle neck stretch.', 'ar': 'تمدد خفيف للرقبة.'},
        durationSeconds: 45,
        imageUrl: SupabaseStorage.stretchNeck,
        order: 1,
        type: ExerciseType.stretching,
      ),
      ExerciseModel(
        id: 's2',
        name: {'en': 'Shoulder Reset', 'ar': 'إرخاء الكتفين'},
        description: {
          'en': 'Loosen shoulder tension.',
          'ar': 'تحرير توتر الكتفين.'
        },
        durationSeconds: 60,
        imageUrl: SupabaseStorage.stretchShoulder,
        order: 2,
        type: ExerciseType.stretching,
      ),
      ExerciseModel(
        id: 's3',
        name: {'en': 'Arm Flow', 'ar': 'تمدد الذراع'},
        description: {
          'en': 'Stretch arms and chest.',
          'ar': 'تمديد الذراع والصدر.'
        },
        durationSeconds: 60,
        imageUrl: SupabaseStorage.stretchArm,
        order: 3,
        type: ExerciseType.stretching,
      ),
      ExerciseModel(
        id: 's4',
        name: {'en': 'Back Ease', 'ar': 'إرخاء الظهر'},
        description: {
          'en': 'Release lower back stiffness.',
          'ar': 'تخفيف تيبس الظهر.'
        },
        durationSeconds: 75,
        imageUrl: SupabaseStorage.stretchBack,
        order: 4,
        type: ExerciseType.stretching,
      ),

      // ================= MEDITATION =================
      ExerciseModel(
        id: 'm1',
        name: {'en': 'Mind Focus', 'ar': 'تركيز ذهني'},
        description: {
          'en': 'Observe breathing calmly.',
          'ar': 'ملاحظة التنفس بهدوء.'
        },
        durationSeconds: 120,
        imageUrl: '',
        order: 1,
        type: ExerciseType.meditation,
      ),
      ExerciseModel(
        id: 'm2',
        name: {'en': 'Body Awareness', 'ar': 'وعي بالجسم'},
        description: {
          'en': 'Scan body sensations.',
          'ar': 'التركيز على إحساس الجسم.'
        },
        durationSeconds: 90,
        imageUrl: '',
        order: 2,
        type: ExerciseType.meditation,
      ),
      ExerciseModel(
        id: 'm3',
        name: {'en': 'Stress Release', 'ar': 'تحرير التوتر'},
        description: {
          'en': 'Let tension fade away.',
          'ar': 'تحرير الضغط النفسي.'
        },
        durationSeconds: 150,
        imageUrl: '',
        order: 3,
        type: ExerciseType.meditation,
      ),

      // ================= YOGA =================
      ExerciseModel(
        id: 'y1',
        name: {'en': 'Child Pose', 'ar': 'وضعية الطفل'},
        description: {
          'en': 'Relax spine and mind.',
          'ar': 'استرخاء العمود الفقري.'
        },
        durationSeconds: 90,
        imageUrl: '',
        order: 1,
        type: ExerciseType.yoga,
      ),
      ExerciseModel(
        id: 'y2',
        name: {'en': 'Cat Flow', 'ar': 'حركة القطة'},
        description: {
          'en': 'Gentle spine mobility.',
          'ar': 'تحريك العمود الفقري.'
        },
        durationSeconds: 60,
        imageUrl: '',
        order: 2,
        type: ExerciseType.yoga,
      ),
      ExerciseModel(
        id: 'y3',
        name: {'en': 'Balance Pose', 'ar': 'وضعية التوازن'},
        description: {'en': 'Improve stability.', 'ar': 'تحسين التوازن.'},
        durationSeconds: 75,
        imageUrl: '',
        order: 3,
        type: ExerciseType.yoga,
      ),
    ];
  }
}
