import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/features/health/view/exercise_list_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/language_cubit.dart';

import '../viewmodel/health_cubit.dart';
import '../viewmodel/health_state.dart';
import '../model/exercise_model.dart'; // Import added
import 'deep_breathing_screen.dart';
import 'stretching_screen.dart';
// import 'exercise_list_screen.dart'; // Removed to avoid confusion

class EmergencyLevelScreen extends StatefulWidget {
  const EmergencyLevelScreen({super.key});

  @override
  State<EmergencyLevelScreen> createState() => _EmergencyLevelScreenState();
}

class _EmergencyLevelScreenState extends State<EmergencyLevelScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HealthCubit>().loadHealthData();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocBuilder<HealthCubit, HealthState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'health.emergency_level'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: _buildContent(context, state, lang, isLarge),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, HealthState state, String lang, bool isLarge) {
    if (state is HealthLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is HealthError) {
      return Center(child: Text(state.message));
    }

    int emergencyLevel = 5; // Default value

    if (state is HealthLoaded) {
      emergencyLevel = state.emergencyLevel;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isLarge ? 32 : 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Level Card
          _buildEmergencyLevelCard(context, emergencyLevel, isLarge),

          SizedBox(height: isLarge ? 24 : 16.h),

          // Heart Rate Card Removed
          // _buildHeartRateCard(...)

          SizedBox(height: isLarge ? 32 : 24.h),

          // Recommended Techniques
          Text(
            'health.recommended_techniques'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 20 : 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isLarge ? 16 : 12.h),

          // Deep Breathing
          Column(
            children: [
              _buildTechniqueCard(
                icon: '🧘',
                title: 'health.deep_breathing'.tr(),
                subtitle: '5 ${lang == 'ar' ? 'دقائق' : 'min'}',
                isRecommended: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeepBreathingScreen(),
                    ),
                  );
                },
                isLarge: isLarge,
              ),
              SizedBox(height: 12.h),
              _buildTechniqueCard(
                icon: '🏃',
                title: 'health.gentle_stretching'.tr(),
                subtitle: '10 ${lang == 'ar' ? 'دقائق' : 'min'}',
                isRecommended: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StretchingScreen(),
                    ),
                  );
                },
                isLarge: isLarge,
              ),
              SizedBox(height: 12.h),
              _buildTechniqueCard(
                icon: '🧠',
                title: 'health.meditation'.tr(),
                subtitle: '10 ${lang == 'ar' ? 'دقائق' : 'min'}',
                isRecommended: false,
                onTap: () => _navigateToCategory(
                    context, ExerciseType.meditation, 'health.meditation'.tr()),
                isLarge: isLarge,
              ),
              SizedBox(height: 12.h),
              _buildTechniqueCard(
                icon: '🧘‍♀️',
                title: 'health.yoga'.tr(),
                subtitle: '15 ${lang == 'ar' ? 'دقائق' : 'min'}',
                isRecommended: false,
                onTap: () => _navigateToCategory(
                    context, ExerciseType.yoga, 'health.yoga'.tr()),
                isLarge: isLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyLevelCard(
      BuildContext context, int level, bool isLarge) {
    final color = level <= 3
        ? AppColors.error
        : level <= 7
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 20.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'health.current_level'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 16 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // يمكن إضافة dialog لتعديل المستوى يدوياً
                },
                child: Text(
                  'health.update'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 14 : 12.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 16 : 12.h),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: level / 10,
                    minHeight: isLarge ? 12 : 10.h,
                    backgroundColor: AppColors.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              SizedBox(width: isLarge ? 16 : 12.w),
              Text(
                '$level/10',
                style: TextStyle(
                  fontSize: isLarge ? 18 : 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          SizedBox(height: isLarge ? 12 : 8.h),

          Text(
            'health.last_updated'.tr(args: ['2']),
            style: TextStyle(
              fontSize: isLarge ? 12 : 11.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(
      BuildContext context, ExerciseType type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseListScreen(type: type, title: title),
      ),
    );
  }

  // _buildHeartRateCard removed

  Widget _buildTechniqueCard({
    required String icon,
    required String title,
    required String subtitle,
    required bool isRecommended,
    required VoidCallback onTap,
    required bool isLarge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 16 : 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRecommended ? AppColors.primary : AppColors.lightGrey,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isLarge ? 56 : 48.w,
              height: isLarge ? 56 : 48.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: TextStyle(fontSize: isLarge ? 28 : 24.sp),
                ),
              ),
            ),
            SizedBox(width: isLarge ? 16 : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isLarge ? 15 : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isRecommended) ...[
                        SizedBox(width: isLarge ? 8 : 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLarge ? 8 : 6.w,
                            vertical: isLarge ? 2 : 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'health.recommended'.tr(),
                            style: TextStyle(
                              fontSize: isLarge ? 9 : 8.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isLarge ? 4 : 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: isLarge ? 40 : 36.w,
              height: isLarge ? 40 : 36.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.play_arrow,
                color: AppColors.white,
                size: isLarge ? 24 : 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
