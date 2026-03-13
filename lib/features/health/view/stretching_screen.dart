import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_storage.dart';
import '../model/exercise_model.dart';
import '../model/exercise_progress_model.dart';
import '../viewmodel/health_cubit.dart';
import '../viewmodel/health_state.dart';

class StretchingScreen extends StatefulWidget {
  final ExerciseModel? exercise;

  const StretchingScreen({super.key, this.exercise});

  @override
  State<StretchingScreen> createState() => _StretchingScreenState();
}


class _StretchingScreenState extends State<StretchingScreen> {
  int _currentIndex = 0;
  int _secondsRemaining = 30;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _timer;

  // تمارين افتراضية في حال عدم وجود بيانات من Firebase
  final List<Map<String, dynamic>> _defaultExercises = [
    {
      'name': {'en': 'Neck Stretch', 'ar': 'تمدد الرقبة'},
      'description': {
        'en': 'Tilt your head slowly to the right, hold for 15 seconds, then repeat on the left side.',
        'ar': 'أمل رأسك ببطء إلى اليمين، استمر لمدة 15 ثانية، ثم كرر على الجانب الأيسر.'
      },
      'duration': 30,
      'imageUrl': SupabaseStorage.stretchNeck,
    },
    {
      'name': {'en': 'Shoulder Rolls', 'ar': 'دوران الكتف'},
      'description': {
        'en': 'Roll your shoulders forward in circular motions, then reverse direction.',
        'ar': 'قم بتدوير كتفيك للأمام في حركات دائرية، ثم اعكس الاتجاه.'
      },
      'duration': 30,
      'imageUrl': SupabaseStorage.stretchShoulder,
    },
    {
      'name': {'en': 'Arm Stretch', 'ar': 'تمدد الذراع'},
      'description': {
        'en': 'Extend your right arm across your chest, use your left hand to gently pull it closer.',
        'ar': 'مدد ذراعك اليمنى عبر صدرك، واستخدم يدك اليسرى لسحبها برفق.'
      },
      'duration': 30,
      'imageUrl': SupabaseStorage.stretchArm,
    },
    {
      'name': {'en': 'Back Stretch', 'ar': 'تمدد الظهر'},
      'description': {
        'en': 'Stand up, place your hands on your lower back, and gently lean backward.',
        'ar': 'قف، ضع يديك على أسفل ظهرك، وانحنِ للخلف برفق.'
      },
      'duration': 30,
      'imageUrl': SupabaseStorage.stretchBack,
    },
    {
      'name': {'en': 'Deep Breath', 'ar': 'نفس عميق'},
      'description': {
        'en': 'Take a deep breath in through your nose, hold for 4 seconds, then exhale slowly.',
        'ar': 'خذ نفسًا عميقًا من أنفك، احبسه لمدة 4 ثوانٍ، ثم أخرجه ببطء.'
      },
      'duration': 30,
      'imageUrl': SupabaseStorage.stretchBreath,
    },
  ];

  List<ExerciseModel> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    if (widget.exercise != null) {
      _exercises = [widget.exercise!];
    } else {
      final state = context.read<HealthCubit>().state;
      if (state is HealthLoaded && state.exercises.isNotEmpty) {
        _exercises = state.exercises
            .where((e) => e.type == ExerciseType.stretching && e.imageUrl.isNotEmpty)
            .toList();
      }

      if (_exercises.isEmpty) {
        // استخدام التمارين الافتراضية
        _exercises = _defaultExercises.map((e) => ExerciseModel(
          id: '', // Default ID, won't be tracked correctly if empty, but fallback is fallback
          name: Map<String, String>.from(e['name']),
          description: Map<String, String>.from(e['description']),
          durationSeconds: e['duration'],
          imageUrl: e['imageUrl'],
          order: _defaultExercises.indexOf(e),
          type: ExerciseType.stretching,
        )).toList();
      }
    }

    _secondsRemaining = _exercises.isNotEmpty ? _exercises[0].durationSeconds : 30;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        _nextExercise();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });
  }

  void _pauseExercise() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeExercise() {
    setState(() {
      _isRunning = true;
    });
    _startTimer();
  }

  void _nextExercise() {
    _timer?.cancel();

    if (_currentIndex >= _exercises.length - 1) {
      _completeSession();
      return;
    }

    setState(() {
      _currentIndex++;
      _secondsRemaining = _exercises[_currentIndex].durationSeconds;
    });

    if (_isRunning) {
      _startTimer();
    }
  }

  void _previousExercise() {
    if (_currentIndex <= 0) return;

    _timer?.cancel();

    setState(() {
      _currentIndex--;
      _secondsRemaining = _exercises[_currentIndex].durationSeconds;
    });

    if (_isRunning) {
      _startTimer();
    }
  }

  void _completeSession() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
    
    // Mark as completed
    for (var ex in _exercises) {
      if (ex.id.isNotEmpty) {
        final pointsEarned = ExercisePointsSystem.getPointsForExercise(
          ex.type.name,
          ex.durationSeconds,
        );
        
        context.read<HealthCubit>().completeExercise(
          ex.id,
          ex.type.name,
          ex.durationSeconds,
          pointsEarned,
        );
      }
    }
  }

  void _resetSession() {
    _timer?.cancel();
    setState(() {
      _currentIndex = 0;
      _secondsRemaining = _exercises.isNotEmpty ? _exercises[0].durationSeconds : 30;
      _isRunning = false;
      _isCompleted = false;
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
          'health.gentle_stretching'.tr(),
          style: TextStyle(
            fontSize: isLarge ? 20 : 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _exercises.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _isCompleted
                ? _buildCompletedState(lang, isLarge)
                : _buildExerciseState(lang, isLarge),
      ),
    );
  }

  Widget _buildExerciseState(String lang, bool isLarge) {
    final exercise = _exercises[_currentIndex];

    return Padding(
      padding: EdgeInsets.all(isLarge ? 32 : 16.w),
      child: Column(
        children: [
          // Progress indicator
          Row(
            children: List.generate(_exercises.length, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    color: index <= _currentIndex
                        ? AppColors.primary
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: isLarge ? 16 : 12.h),

          // Exercise counter
          Text(
            '${lang == 'ar' ? 'التمرين' : 'Exercise'} ${_currentIndex + 1}/${_exercises.length}',
            style: TextStyle(
              fontSize: isLarge ? 14 : 12.sp,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: isLarge ? 24 : 16.h),

          // Exercise image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: exercise.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: isLarge ? 80 : 64.sp,
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          exercise.getName(lang),
                          style: TextStyle(
                            fontSize: isLarge ? 18 : 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isLarge ? 24 : 16.h),

          // Exercise info
          Container(
            padding: EdgeInsets.all(isLarge ? 20 : 16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  exercise.getName(lang),
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: isLarge ? 8 : 6.h),

                Text(
                  exercise.getDescription(lang),
                  style: TextStyle(
                    fontSize: isLarge ? 14 : 13.sp,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isLarge ? 16 : 12.h),

                // Timer
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
                      '$_secondsRemaining',
                      style: TextStyle(
                        fontSize: isLarge ? 32 : 28.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      ' ${lang == 'ar' ? 'ثانية' : 'sec'}',
                      style: TextStyle(
                        fontSize: isLarge ? 16 : 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: isLarge ? 24 : 16.h),

          // Controls
          Row(
            children: [
              // Previous
              IconButton(
                onPressed: _currentIndex > 0 ? _previousExercise : null,
                icon: Icon(
                  Icons.skip_previous,
                  size: isLarge ? 36 : 32.sp,
                  color: _currentIndex > 0 ? AppColors.primary : AppColors.lightGrey,
                ),
              ),

              // Play/Pause
              Expanded(
                child: SizedBox(
                  height: isLarge ? 56 : 48.h,
                  child: ElevatedButton(
                    onPressed: _isRunning
                        ? _pauseExercise
                        : (_secondsRemaining == _exercises[_currentIndex].durationSeconds
                            ? _startExercise
                            : _resumeExercise),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? AppColors.warning : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: AppColors.white,
                      size: isLarge ? 32 : 28.sp,
                    ),
                  ),
                ),
              ),

              // Next
              IconButton(
                onPressed: _nextExercise,
                icon: Icon(
                  Icons.skip_next,
                  size: isLarge ? 36 : 32.sp,
                  color: AppColors.primary,
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
              lang == 'ar' ? 'ممتاز!' : 'Excellent!',
              style: TextStyle(
                fontSize: isLarge ? 28 : 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: isLarge ? 12 : 8.h),

            Text(
              lang == 'ar'
                  ? 'لقد أكملت جميع تمارين التمدد'
                  : 'You completed all stretching exercises',
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
                    '${_exercises.length}',
                    style: TextStyle(
                      fontSize: isLarge ? 36 : 32.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    lang == 'ar' ? 'تمرين مكتمل' : 'Exercises Completed',
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
              onPressed: _resetSession,
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
}
