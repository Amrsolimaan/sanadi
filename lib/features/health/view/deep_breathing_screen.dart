import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/exercise_model.dart';
import '../model/exercise_progress_model.dart';
import '../viewmodel/health_cubit.dart';

class DeepBreathingScreen extends StatefulWidget {
  final ExerciseModel? exercise;

  const DeepBreathingScreen({super.key, this.exercise});

  @override
  State<DeepBreathingScreen> createState() => _DeepBreathingScreenState();
}

class _DeepBreathingScreenState extends State<DeepBreathingScreen>
    with TickerProviderStateMixin {
  // إعدادات التمرين
  late BreathingExerciseConfig _config;

  // الحالة
  bool _isRunning = false;
  bool _isCompleted = false;
  BreathingPhase _currentPhase = BreathingPhase.breatheIn;
  int _phaseSecondsRemaining = 4;
  int _totalSecondsRemaining = 5 * 60;
  int _completedCycles = 0;

  // Animation
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initConfig();
    
    _phaseSecondsRemaining = _config.breatheInSeconds;
    _totalSecondsRemaining = _config.totalDurationMinutes * 60;
    
    _circleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _config.breatheInSeconds > 0 ? _config.breatheInSeconds : 1),
    );
    _circleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );
  }

  void _initConfig() {
    if (widget.exercise != null) {
      switch (widget.exercise!.id) {
        case 'b1': // 4-7-8
          _config = const BreathingExerciseConfig(breatheInSeconds: 4, holdSeconds: 7, breatheOutSeconds: 8, holdAfterOutSeconds: 0);
          break;
        case 'b2': // Box
          _config = const BreathingExerciseConfig(breatheInSeconds: 4, holdSeconds: 4, breatheOutSeconds: 4, holdAfterOutSeconds: 4);
          break;
        case 'b3': // Deep Calm
          _config = const BreathingExerciseConfig(breatheInSeconds: 5, holdSeconds: 0, breatheOutSeconds: 5, holdAfterOutSeconds: 0);
          break;
        case 'b4': // Morning (Fast)
          _config = const BreathingExerciseConfig(breatheInSeconds: 2, holdSeconds: 0, breatheOutSeconds: 2, holdAfterOutSeconds: 0);
          break;
        case 'b5': // Sleep (Slow 4-7-8)
          _config = const BreathingExerciseConfig(breatheInSeconds: 4, holdSeconds: 7, breatheOutSeconds: 8, holdAfterOutSeconds: 0);
          break;
        default:
          _config = const BreathingExerciseConfig();
      }
    } else {
      _config = const BreathingExerciseConfig();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _currentPhase = BreathingPhase.breatheIn;
      _phaseSecondsRemaining = _config.breatheInSeconds;
      _totalSecondsRemaining = _config.totalDurationMinutes * 60;
      _completedCycles = 0;
    });

    _updateAnimationDuration();
    _circleController.forward();
    _startTimer();
  }
  
  void _updateAnimationDuration() {
     int duration = 1;
     if (_currentPhase == BreathingPhase.breatheIn) duration = _config.breatheInSeconds;
     else if (_currentPhase == BreathingPhase.breatheOut) duration = _config.breatheOutSeconds;
     
     if (duration <= 0) duration = 1;
     _circleController.duration = Duration(seconds: duration);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSecondsRemaining <= 0) {
        _completeExercise();
        return;
      }

      setState(() {
        _totalSecondsRemaining--;
        _phaseSecondsRemaining--;

        if (_phaseSecondsRemaining <= 0) {
          _nextPhase();
        }
      });
    });
  }

  void _nextPhase() {
    switch (_currentPhase) {
      case BreathingPhase.breatheIn:
        if (_config.holdSeconds > 0) {
          _currentPhase = BreathingPhase.hold;
          _phaseSecondsRemaining = _config.holdSeconds;
          // Circle stays expanded
        } else {
          _currentPhase = BreathingPhase.breatheOut;
          _phaseSecondsRemaining = _config.breatheOutSeconds;
          _updateAnimationDuration();
          _circleController.reverse();
        }
        break;
      case BreathingPhase.hold:
        _currentPhase = BreathingPhase.breatheOut;
        _phaseSecondsRemaining = _config.breatheOutSeconds;
        _updateAnimationDuration();
        _circleController.reverse();
        break;
      case BreathingPhase.breatheOut:
        if (_config.holdAfterOutSeconds > 0) {
           _currentPhase = BreathingPhase.holdAfterOut;
           _phaseSecondsRemaining = _config.holdAfterOutSeconds;
           // Circle stays contracted
        } else {
           _startNewCycle();
        }
        break;
      case BreathingPhase.holdAfterOut:
        _startNewCycle();
        break;
    }
  }

  void _startNewCycle() {
    _currentPhase = BreathingPhase.breatheIn;
    _phaseSecondsRemaining = _config.breatheInSeconds;
    _completedCycles++;
    _updateAnimationDuration();
    _circleController.forward();
  }

  void _pauseExercise() {
    _timer?.cancel();
    _circleController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeExercise() {
    setState(() {
      _isRunning = true;
    });
    
    if (_currentPhase == BreathingPhase.breatheIn) {
      _circleController.forward();
    } else if (_currentPhase == BreathingPhase.breatheOut) {
      _circleController.reverse();
    }
    
    _startTimer();
  }

  void _completeExercise() {
    _timer?.cancel();
    _circleController.stop();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });

    if (widget.exercise != null) {
      final durationSeconds = widget.exercise!.durationSeconds;
      final pointsEarned = ExercisePointsSystem.getPointsForExercise(
        widget.exercise!.type.name,
        durationSeconds,
      );
      
      context.read<HealthCubit>().completeExercise(
        widget.exercise!.id,
        widget.exercise!.type.name,
        durationSeconds,
        pointsEarned,
      );
    }
  }

  void _resetExercise() {
    _timer?.cancel();
    _circleController.reset();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _currentPhase = BreathingPhase.breatheIn;
      _phaseSecondsRemaining = _config.breatheInSeconds;
      _totalSecondsRemaining = _config.totalDurationMinutes * 60;
      _completedCycles = 0;
    });
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'health.deep_breathing'.tr(),
          style: TextStyle(
            fontSize: isLarge ? 20 : 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isCompleted
            ? _buildCompletedState(lang, isLarge)
            : _buildExerciseState(lang, isLarge),
      ),
    );
  }

  Widget _buildExerciseState(String lang, bool isLarge) {
    return Padding(
      padding: EdgeInsets.all(isLarge ? 32 : 16.w),
      child: Column(
        children: [
          SizedBox(height: isLarge ? 32 : 24.h),

          // الدائرة المتحركة
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _circleAnimation,
                builder: (context, child) {
                  final size = (isLarge ? 250.0 : 200.w) * _circleAnimation.value;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getPhaseColor().withOpacity(0.3),
                      border: Border.all(
                        color: _getPhaseColor(),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getPhaseEmoji(),
                              style: TextStyle(fontSize: isLarge ? 48 : 40.sp),
                            ),
                            SizedBox(height: isLarge ? 8 : 4.h),
                            Text(
                              _getPhaseText(lang),
                              style: TextStyle(
                                fontSize: isLarge ? 20 : 18.sp,
                                fontWeight: FontWeight.bold,
                                color: _getPhaseColor(),
                              ),
                            ),
                            SizedBox(height: isLarge ? 4 : 2.h),
                            Text(
                              '$_phaseSecondsRemaining',
                              style: TextStyle(
                                fontSize: isLarge ? 32 : 28.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // معلومات التمرين
          Container(
            padding: EdgeInsets.all(isLarge ? 20 : 16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // الوقت المتبقي
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: AppColors.textSecondary,
                      size: isLarge ? 20 : 18.sp,
                    ),
                    SizedBox(width: isLarge ? 8 : 6.w),
                    Text(
                      _formatTime(_totalSecondsRemaining),
                      style: TextStyle(
                        fontSize: isLarge ? 24 : 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ' ${lang == 'ar' ? 'متبقي' : 'remaining'}',
                      style: TextStyle(
                        fontSize: isLarge ? 14 : 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isLarge ? 12 : 8.h),

                // عدد الدورات
                Text(
                  '${lang == 'ar' ? 'الدورات المكتملة' : 'Cycles completed'}: $_completedCycles',
                  style: TextStyle(
                    fontSize: isLarge ? 13 : 12.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isLarge ? 24 : 16.h),

          // أزرار التحكم
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: isLarge ? 56 : 48.h,
                  child: OutlinedButton(
                    onPressed: _resetExercise,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textHint),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      lang == 'ar' ? 'إعادة' : 'Reset',
                      style: TextStyle(
                        fontSize: isLarge ? 14 : 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isLarge ? 16 : 12.w),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: isLarge ? 56 : 48.h,
                  child: ElevatedButton(
                    onPressed: _isRunning
                        ? _pauseExercise
                        : (_totalSecondsRemaining == _config.totalDurationMinutes * 60
                            ? _startExercise
                            : _resumeExercise),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? AppColors.warning : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          color: AppColors.white,
                        ),
                        SizedBox(width: isLarge ? 8 : 6.w),
                        Text(
                          _isRunning
                              ? (lang == 'ar' ? 'إيقاف مؤقت' : 'Pause')
                              : (lang == 'ar' ? 'ابدأ' : 'Start'),
                          style: TextStyle(
                            fontSize: isLarge ? 16 : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isLarge ? 16 : 12.h),
        ],
      ),
    );
  }

  Widget _buildCompletedState(String lang, bool isLarge) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 32 : 16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isLarge ? 120 : 100.w,
              height: isLarge ? 120 : 100.h,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: isLarge ? 60 : 50.sp,
                color: AppColors.white,
              ),
            ),

            SizedBox(height: isLarge ? 32 : 24.h),

            Text(
              lang == 'ar' ? 'أحسنت!' : 'Well Done!',
              style: TextStyle(
                fontSize: isLarge ? 28 : 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: isLarge ? 12 : 8.h),

            Text(
              lang == 'ar'
                  ? 'لقد أكملت تمرين التنفس العميق'
                  : 'You completed the deep breathing exercise',
              style: TextStyle(
                fontSize: isLarge ? 16 : 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isLarge ? 16 : 12.h),

            Container(
              padding: EdgeInsets.all(isLarge ? 20 : 16.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$_completedCycles',
                    style: TextStyle(
                      fontSize: isLarge ? 36 : 32.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    lang == 'ar' ? 'دورة مكتملة' : 'Cycles Completed',
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isLarge ? 48 : 32.h),

            SizedBox(
              width: double.infinity,
              height: isLarge ? 56 : 48.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  lang == 'ar' ? 'إنهاء' : 'Finish',
                  style: TextStyle(
                    fontSize: isLarge ? 16 : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: isLarge ? 12 : 8.h),

            TextButton(
              onPressed: _resetExercise,
              child: Text(
                lang == 'ar' ? 'تمرين مرة أخرى' : 'Exercise Again',
                style: TextStyle(
                  fontSize: isLarge ? 14 : 13.sp,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case BreathingPhase.breatheIn:
        return AppColors.primary;
      case BreathingPhase.hold:
        return AppColors.warning;
      case BreathingPhase.breatheOut:
        return AppColors.success;
      case BreathingPhase.holdAfterOut:
        return AppColors.textSecondary;
    }
  }

  String _getPhaseEmoji() {
    switch (_currentPhase) {
      case BreathingPhase.breatheIn:
        return '💨';
      case BreathingPhase.hold:
        return '⏸️';
      case BreathingPhase.breatheOut:
        return '🌬️';
      case BreathingPhase.holdAfterOut:
        return '🤐';
    }
  }

  String _getPhaseText(String lang) {
    switch (_currentPhase) {
      case BreathingPhase.breatheIn:
        return lang == 'ar' ? 'شهيق' : 'Breathe In';
      case BreathingPhase.hold:
        return lang == 'ar' ? 'احبس' : 'Hold';
      case BreathingPhase.breatheOut:
        return lang == 'ar' ? 'زفير' : 'Breathe Out';
      case BreathingPhase.holdAfterOut:
        return lang == 'ar' ? 'احبس' : 'Hold';
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
