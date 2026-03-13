import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../model/exercise_model.dart';
import '../model/exercise_progress_model.dart';
import '../viewmodel/health_cubit.dart';

/// شاشة تنفيذ موحدة لجميع أنواع التمارين
class UnifiedExerciseRunnerScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const UnifiedExerciseRunnerScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<UnifiedExerciseRunnerScreen> createState() => _UnifiedExerciseRunnerScreenState();
}

class _UnifiedExerciseRunnerScreenState extends State<UnifiedExerciseRunnerScreen>
    with TickerProviderStateMixin {
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _timer;

  // للتمارين التنفسية
  BreathingPhase _currentPhase = BreathingPhase.breatheIn;
  int _phaseSecondsRemaining = 4;
  int _completedCycles = 0;
  late BreathingExerciseConfig _breathingConfig;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.exercise.durationSeconds;
    _secondsRemaining = _totalSeconds;

    if (widget.exercise.type == ExerciseType.breathing) {
      _initBreathingConfig();
      _phaseSecondsRemaining = _breathingConfig.breatheInSeconds;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.exercise.type == ExerciseType.breathing ? 4 : 1),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initBreathingConfig() {
    switch (widget.exercise.id) {
      case 'b1':
        _breathingConfig = const BreathingExerciseConfig(
          breatheInSeconds: 4,
          holdSeconds: 7,
          breatheOutSeconds: 8,
        );
        break;
      case 'b2':
        _breathingConfig = const BreathingExerciseConfig(
          breatheInSeconds: 4,
          holdSeconds: 4,
          breatheOutSeconds: 4,
          holdAfterOutSeconds: 4,
        );
        break;
      case 'b3':
        _breathingConfig = const BreathingExerciseConfig(
          breatheInSeconds: 5,
          holdSeconds: 0,
          breatheOutSeconds: 5,
        );
        break;
      case 'b4':
        _breathingConfig = const BreathingExerciseConfig(
          breatheInSeconds: 3,
          holdSeconds: 0,
          breatheOutSeconds: 3,
        );
        break;
      default:
        _breathingConfig = const BreathingExerciseConfig();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
    });

    if (widget.exercise.type == ExerciseType.breathing) {
      _animationController.forward();
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        _completeExercise();
        return;
      }

      setState(() {
        _secondsRemaining--;

        if (widget.exercise.type == ExerciseType.breathing) {
          _phaseSecondsRemaining--;
          if (_phaseSecondsRemaining <= 0) {
            _nextBreathingPhase();
          }
        }
      });
    });
  }

  void _nextBreathingPhase() {
    switch (_currentPhase) {
      case BreathingPhase.breatheIn:
        if (_breathingConfig.holdSeconds > 0) {
          _currentPhase = BreathingPhase.hold;
          _phaseSecondsRemaining = _breathingConfig.holdSeconds;
        } else {
          _currentPhase = BreathingPhase.breatheOut;
          _phaseSecondsRemaining = _breathingConfig.breatheOutSeconds;
          _animationController.reverse();
        }
        break;
      case BreathingPhase.hold:
        _currentPhase = BreathingPhase.breatheOut;
        _phaseSecondsRemaining = _breathingConfig.breatheOutSeconds;
        _animationController.reverse();
        break;
      case BreathingPhase.breatheOut:
        if (_breathingConfig.holdAfterOutSeconds > 0) {
          _currentPhase = BreathingPhase.holdAfterOut;
          _phaseSecondsRemaining = _breathingConfig.holdAfterOutSeconds;
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
    _phaseSecondsRemaining = _breathingConfig.breatheInSeconds;
    _completedCycles++;
    _animationController.forward();
  }

  void _pauseExercise() {
    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeExercise() {
    setState(() {
      _isRunning = true;
    });

    if (widget.exercise.type == ExerciseType.breathing) {
      if (_currentPhase == BreathingPhase.breatheIn) {
        _animationController.forward();
      } else if (_currentPhase == BreathingPhase.breatheOut) {
        _animationController.reverse();
      }
    }

    _startTimer();
  }

  void _completeExercise() {
    _timer?.cancel();
    _animationController.stop();

    final timeSpent = _totalSeconds - _secondsRemaining;
    final points = ExercisePointsSystem.getPointsForExercise(
      widget.exercise.type.name,
      timeSpent,
    );

    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });

    context.read<HealthCubit>().completeExercise(
      widget.exercise.id,
      widget.exercise.type.name,
      timeSpent,
      points,
    );
  }

  void _resetExercise() {
    _timer?.cancel();
    _animationController.reset();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _secondsRemaining = _totalSeconds;
      _completedCycles = 0;
      _currentPhase = BreathingPhase.breatheIn;
      _phaseSecondsRemaining = widget.exercise.type == ExerciseType.breathing
          ? _breathingConfig.breatheInSeconds
          : 0;
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
          widget.exercise.getName(lang),
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
          SizedBox(height: isLarge ? 24 : 16.h),

          // Visual representation
          Expanded(
            child: _buildExerciseVisual(lang, isLarge),
          ),

          SizedBox(height: isLarge ? 24 : 16.h),

          // Info card
          _buildInfoCard(lang, isLarge),

          SizedBox(height: isLarge ? 24 : 16.h),

          // Controls
          _buildControls(lang, isLarge),

          SizedBox(height: isLarge ? 16 : 12.h),
        ],
      ),
    );
  }

  Widget _buildExerciseVisual(String lang, bool isLarge) {
    if (widget.exercise.type == ExerciseType.breathing) {
      return _buildBreathingVisual(lang, isLarge);
    }
    return _buildStandardVisual(lang, isLarge);
  }

  Widget _buildBreathingVisual(String lang, bool isLarge) {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final size = (isLarge ? 250.0 : 200.w) * _scaleAnimation.value;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getPhaseColor().withValues(alpha: 0.3),
              border: Border.all(color: _getPhaseColor(), width: 4),
            ),
            child: Center(
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
          );
        },
      ),
    );
  }

  Widget _buildStandardVisual(String lang, bool isLarge) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: widget.exercise.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: widget.exercise.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                errorWidget: (context, url, error) => _buildFallbackIcon(lang, isLarge),
              ),
            )
          : _buildFallbackIcon(lang, isLarge),
    );
  }

  Widget _buildFallbackIcon(String lang, bool isLarge) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForType(),
            size: isLarge ? 80 : 64.sp,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.exercise.getName(lang),
            style: TextStyle(
              fontSize: isLarge ? 18 : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String lang, bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            widget.exercise.getDescription(lang),
            style: TextStyle(
              fontSize: isLarge ? 14 : 13.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isLarge ? 16 : 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: AppColors.primary,
                size: isLarge ? 24 : 20.sp,
              ),
              SizedBox(width: isLarge ? 8 : 6.w),
              Text(
                _formatTime(_secondsRemaining),
                style: TextStyle(
                  fontSize: isLarge ? 32 : 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (widget.exercise.type == ExerciseType.breathing) ...[
            SizedBox(height: isLarge ? 12 : 8.h),
            Text(
              '${lang == 'ar' ? 'الدورات المكتملة' : 'Cycles'}: $_completedCycles',
              style: TextStyle(
                fontSize: isLarge ? 13 : 12.sp,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(String lang, bool isLarge) {
    return Row(
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
                  : (_secondsRemaining == _totalSeconds ? _startExercise : _resumeExercise),
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
                        ? (lang == 'ar' ? 'إيقاف' : 'Pause')
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
    );
  }

  Widget _buildCompletedState(String lang, bool isLarge) {
    final points = ExercisePointsSystem.getPointsForExercise(
      widget.exercise.type.name,
      _totalSeconds,
    );

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
              lang == 'ar' ? 'لقد أكملت التمرين بنجاح' : 'You completed the exercise',
              style: TextStyle(
                fontSize: isLarge ? 16 : 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: isLarge ? 24 : 16.h),
            Container(
              padding: EdgeInsets.all(isLarge ? 20 : 16.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '+$points',
                        style: TextStyle(
                          fontSize: isLarge ? 36 : 32.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        lang == 'ar' ? 'نقطة' : 'Points',
                        style: TextStyle(
                          fontSize: isLarge ? 14 : 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40.h,
                    color: AppColors.lightGrey,
                  ),
                  Column(
                    children: [
                      Text(
                        _formatTime(_totalSeconds),
                        style: TextStyle(
                          fontSize: isLarge ? 36 : 32.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        lang == 'ar' ? 'الوقت' : 'Time',
                        style: TextStyle(
                          fontSize: isLarge ? 14 : 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

  IconData _getIconForType() {
    switch (widget.exercise.type) {
      case ExerciseType.breathing:
        return Icons.air;
      case ExerciseType.stretching:
        return Icons.accessibility_new;
      case ExerciseType.meditation:
        return Icons.self_improvement;
      case ExerciseType.yoga:
        return Icons.spa;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
