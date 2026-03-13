import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../model/exercise_model.dart';
import '../viewmodel/health_cubit.dart';
import '../viewmodel/health_state.dart';
import 'unified_exercise_runner_screen.dart';

class ExerciseListScreen extends StatelessWidget {
  final ExerciseType type;
  final String title;

  const ExerciseListScreen({
    super.key,
    required this.type,
    required this.title,
  });

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isLarge ? 20 : 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HealthCubit, HealthState>(
        builder: (context, state) {
          if (state is! HealthLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = state.exercises
              .where((e) => e.type == type)
              .toList();
          
          final completedIds = state.completedExerciseIds;

          if (exercises.isEmpty) {
            return Center(
              child: Text(
                'health.no_exercises'.tr(),
                style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(isLarge ? 32 : 16.w),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => SizedBox(height: isLarge ? 16 : 12.h),
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final isCompleted = completedIds.contains(exercise.id);

              return _buildExerciseCard(context, exercise, isCompleted, lang, isLarge);
            },
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ExerciseModel exercise,
    bool isCompleted,
    String lang,
    bool isLarge,
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToExercise(context, exercise);
      },
      child: Container(
        padding: EdgeInsets.all(isLarge ? 16 : 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: isCompleted ? Border.all(color: AppColors.primary, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon / Image
            Container(
              width: isLarge ? 64 : 56.w,
              height: isLarge ? 64 : 56.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: exercise.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: exercise.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_,__,___) => Icon(Icons.fitness_center, color: AppColors.primary),
                      ),
                    )
                  : Icon(
                      _getIconForType(exercise.type),
                      color: AppColors.primary,
                      size: isLarge ? 32 : 28.sp,
                    ),
            ),
            SizedBox(width: isLarge ? 16 : 12.w),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.getName(lang),
                          style: TextStyle(
                            fontSize: isLarge ? 16 : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Icon(Icons.check_circle, color: AppColors.primary, size: isLarge ? 20 : 16.sp),
                    ],
                  ),
                  SizedBox(height: isLarge ? 4 : 2.h),
                  Text(
                    exercise.getDescription(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: isLarge ? 4 : 4.h),
                  Text(
                    exercise.getFormattedDuration(),
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 11.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(ExerciseType type) {
    switch (type) {
      case ExerciseType.breathing: return Icons.air;
      case ExerciseType.stretching: return Icons.accessibility_new;
      case ExerciseType.meditation: return Icons.self_improvement;
      case ExerciseType.yoga: return Icons.fitness_center; // or spa
    }
  }

  void _navigateToExercise(BuildContext context, ExerciseModel exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedExerciseRunnerScreen(exercise: exercise),
      ),
    );
  }
}
