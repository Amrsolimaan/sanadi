import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../model/exercise_progress_model.dart';
import '../viewmodel/health_cubit.dart';
import '../viewmodel/health_state.dart';

class ExerciseStatsScreen extends StatelessWidget {
  const ExerciseStatsScreen({super.key});

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'exercise_stats'.tr(),
          style: TextStyle(
            fontSize: isLarge ? 24.sp : 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HealthCubit, HealthState>(
        builder: (context, state) {
          if (state is HealthLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state is HealthError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: isLarge ? 80.sp : 64.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: isLarge ? 18.sp : 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HealthCubit>().loadHealthData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'retry'.tr(),
                      style: TextStyle(fontSize: isLarge ? 16.sp : 14.sp),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is HealthLoaded) {
            final stats = state.userStats;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(isLarge ? 24.w : 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, stats, isLarge),
                  SizedBox(height: 20.h),
                  _buildStreakCard(context, stats, isLarge),
                  SizedBox(height: 20.h),
                  _buildExerciseTypeBreakdown(context, stats, isLarge),
                  SizedBox(height: 20.h),
                  _buildPointsCard(context, stats, isLarge),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    UserExerciseStats stats,
    bool isLarge,
  ) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24.w : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'overall_stats'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 20.sp : 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                Icons.fitness_center,
                stats.totalExercisesCompleted.toString(),
                'exercises'.tr(),
                isLarge,
              ),
              _buildStatItem(
                context,
                Icons.timer,
                stats.getFormattedTotalTime(),
                'total_time'.tr(),
                isLarge,
              ),
              _buildStatItem(
                context,
                Icons.star,
                stats.totalPoints.toString(),
                'points'.tr(),
                isLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    bool isLarge,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: isLarge ? 40.sp : 32.sp,
          color: AppColors.primary,
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 24.sp : 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 14.sp : 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    UserExerciseStats stats,
    bool isLarge,
  ) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24.w : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'streak_info'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 20.sp : 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: isLarge ? 48.sp : 40.sp,
                    color: AppColors.logoOrange,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    stats.currentStreak.toString(),
                    style: TextStyle(
                      fontSize: isLarge ? 32.sp : 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'current_streak'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 14.sp : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 80.h,
                color: AppColors.divider,
              ),
              Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: isLarge ? 48.sp : 40.sp,
                    color: AppColors.logoYellow,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    stats.longestStreak.toString(),
                    style: TextStyle(
                      fontSize: isLarge ? 32.sp : 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'longest_streak'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 14.sp : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTypeBreakdown(
    BuildContext context,
    UserExerciseStats stats,
    bool isLarge,
  ) {
    if (stats.exerciseTypeCount.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isLarge ? 24.w : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'exercise_breakdown'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 20.sp : 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ...stats.exerciseTypeCount.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getExerciseTypeIcon(entry.key),
                        size: isLarge ? 24.sp : 20.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        entry.key.tr(),
                        style: TextStyle(
                          fontSize: isLarge ? 16.sp : 14.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${entry.value} ${'times'.tr()}',
                    style: TextStyle(
                      fontSize: isLarge ? 16.sp : 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPointsCard(
    BuildContext context,
    UserExerciseStats stats,
    bool isLarge,
  ) {
    final currentLevel = ExercisePointsSystem.getLevelFromPoints(stats.totalPoints);
    final pointsNeeded = ExercisePointsSystem.getPointsNeededForNextLevel(stats.totalPoints);
    
    return Container(
      padding: EdgeInsets.all(isLarge ? 24.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'level'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 20.sp : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  currentLevel.toString(),
                  style: TextStyle(
                    fontSize: isLarge ? 24.sp : 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '${stats.totalPoints} ${'points'.tr()}',
            style: TextStyle(
              fontSize: isLarge ? 32.sp : 28.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          if (pointsNeeded > 0) ...[
            SizedBox(height: 8.h),
            Text(
              '$pointsNeeded ${'points_to_next_level'.tr()}',
              style: TextStyle(
                fontSize: isLarge ? 14.sp : 12.sp,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ] else ...[
            SizedBox(height: 8.h),
            Text(
              'max_level_reached'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 14.sp : 12.sp,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getExerciseTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breathing':
        return Icons.air;
      case 'stretching':
        return Icons.accessibility_new;
      case 'meditation':
        return Icons.self_improvement;
      case 'yoga':
        return Icons.spa;
      default:
        return Icons.fitness_center;
    }
  }
}