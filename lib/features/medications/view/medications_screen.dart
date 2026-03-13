import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/utils/page_transitions.dart';
import '../viewmodel/medication_cubit.dart';
import '../viewmodel/medication_state.dart';
import '../model/medication_model.dart';
import '../model/medication_log_model.dart';
import 'add_medication_screen.dart';
import 'medication_details_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  // ✅ Selection Mode Variables
  bool _isSelectionMode = false;
  final Set<String> _selectedMedications = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationCubit>().loadMedications();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMedications.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMedications.contains(id)) {
        _selectedMedications.remove(id);
      } else {
        _selectedMedications.add(id);
      }
    });
  }

  void _selectAll(List<MedicationModel> medications) {
    setState(() {
      _selectedMedications.addAll(medications.map((m) => m.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedMedications.clear();
    });
  }

  void _deleteSelected(BuildContext context) {
    if (_selectedMedications.isEmpty) return;

    final lang = context.locale.languageCode;
    final count = _selectedMedications.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'ar' ? 'حذف الأدوية' : 'Delete Medications'),
        content: Text(
          lang == 'ar'
              ? 'هل أنت متأكد من حذف $count أدوية؟'
              : 'Are you sure you want to delete $count medications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MedicationCubit>().deleteMultipleMedications(
                    _selectedMedications.toList(),
                  );
              _toggleSelectionMode();
            },
            child: Text(
              lang == 'ar' ? 'حذف' : 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'medications.my_medications'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _navigateToAdd(context),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<MedicationCubit, MedicationState>(
          listener: (context, state) {
            final lang = context.locale.languageCode;

            if (state is MedicationDoseTaken) {
              _showSuccessSnackBar(
                context,
                lang == 'ar'
                    ? 'تم تناول ${state.medicationName} بنجاح'
                    : '${state.medicationName} taken successfully',
              );
            }
            if (state is MedicationDoseSkipped) {
              _showInfoSnackBar(
                context,
                lang == 'ar'
                    ? 'تم تخطي ${state.medicationName}'
                    : '${state.medicationName} skipped',
              );
            }
            // ✅ Handle multiple deletion success
            if (state is MedicationsDeleted) {
              _showSuccessSnackBar(
                context,
                lang == 'ar'
                    ? 'تم حذف ${state.count} أدوية بنجاح'
                    : '${state.count} medications deleted successfully',
              );
            }
          },
          builder: (context, state) {
            if (state is MedicationLoading) {
              return const MedicationsShimmerLoading();
            }

            if (state is MedicationError) {
              return _buildErrorState(context, state.message);
            }

            if (state is MedicationEmpty) {
              return _buildEmptyState(context);
            }

            if (state is MedicationLoaded) {
              return _buildContent(context, state);
            }

            return const MedicationsShimmerLoading();
          },
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return TapScaleWidget(
      onTap: () => _navigateToAdd(context),
      child: Container(
        width: 56.w,
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(const AddMedicationScreen()),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SuccessAnimation(size: 24, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return FadeInWidget(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
              SizedBox(height: 16.h),
              Text(
                'medications.error'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24.h),
              TapScaleWidget(
                onTap: () => context.read<MedicationCubit>().loadMedications(),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'general.retry'.tr(),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return FadeInWidget(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_outlined,
                  size: 48.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'medications.empty_title'.tr(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'medications.empty_message'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 32.h),
              TapScaleWidget(
                onTap: () => _navigateToAdd(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppColors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'medications.add_first'.tr(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MedicationLoaded state) {
    final lang = context.locale.languageCode;
    final isRtl = lang == 'ar';

    return RefreshIndicator(
      onRefresh: () => context.read<MedicationCubit>().loadMedications(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Schedule Section
            FadeInWidget(
              child: Text(
                'medications.today_schedule'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            if (state.todaySchedule.isEmpty)
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: _buildEmptySchedule(),
              )
            else
              ...state.todaySchedule.asMap().entries.map((entry) {
                return StaggeredListItem(
                  index: entry.key,
                  baseDelay: const Duration(milliseconds: 100),
                  child: _buildScheduleGroup(context, entry.value, lang, isRtl),
                );
              }),

            SizedBox(height: 24.h),

            // All Medications Section Header
            FadeInWidget(
              delay: const Duration(milliseconds: 200),
              child: _isSelectionMode
                  ? _buildSelectionHeader(state.medications)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'medications.all_medications'.tr(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (state.medications.isNotEmpty)
                          InkWell(
                            onTap: _toggleSelectionMode,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16.sp,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    context.locale.languageCode == 'ar'
                                        ? 'تعديل'
                                        : 'Edit',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            SizedBox(height: 16.h),

            if (state.medications.isEmpty)
              FadeInWidget(
                delay: const Duration(milliseconds: 250),
                child: _buildEmptyMedications(),
              )
            else
              ...state.medications.asMap().entries.map((entry) {
                return StaggeredListItem(
                  index: entry.key,
                  baseDelay: const Duration(milliseconds: 250),
                  child: _buildMedicationListItem(
                    context,
                    entry.value,
                    lang,
                    isRtl,
                  ),
                );
              }),

            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.h,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 32.sp,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'medications.all_done'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'medications.all_done_message'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Selection Mode Header
  Widget _buildSelectionHeader(List<MedicationModel> medications) {
    final allSelected = _selectedMedications.length == medications.length &&
        medications.isNotEmpty;
    final lang = context.locale.languageCode;

    return Column(
      children: [
        // Top row: Title + Cancel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang == 'ar' ? 'تحديد الأدوية' : 'Select Medications',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _toggleSelectionMode,
              child: Text(
                lang == 'ar' ? 'إلغاء' : 'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Bottom row: Select All + Delete Button
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Select All Checkbox
              InkWell(
                onTap: () {
                  if (allSelected) {
                    _deselectAll();
                  } else {
                    _selectAll(medications);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      allSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: AppColors.primary,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      allSelected
                          ? (lang == 'ar' ? 'إلغاء الكل' : 'Deselect All')
                          : (lang == 'ar' ? 'تحديد الكل' : 'Select All'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Selected count badge
              if (_selectedMedications.isNotEmpty)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedMedications.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              SizedBox(width: 12.w),

              // Delete Button
              InkWell(
                onTap: _selectedMedications.isNotEmpty
                    ? () => _deleteSelected(context)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _selectedMedications.isNotEmpty
                        ? AppColors.error
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: _selectedMedications.isNotEmpty
                            ? AppColors.white
                            : AppColors.textHint,
                        size: 18.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        lang == 'ar' ? 'حذف' : 'Delete',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: _selectedMedications.isNotEmpty
                              ? AppColors.white
                              : AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMedications() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Center(
        child: Text(
          'medications.no_medications'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleGroup(
    BuildContext context,
    ScheduleGroup group,
    String lang,
    bool isRtl,
  ) {
    final cubit = context.read<MedicationCubit>();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  cubit.getPeriodIcon(group.period),
                  style: TextStyle(fontSize: 20.sp),
                ),
                SizedBox(width: 8.w),
                Text(
                  cubit.getPeriodName(group.period, lang),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatTime(group.time),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.lightGrey.withOpacity(0.5)),

          // Medication Cards
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Column(
              children: group.doses
                  .map((dose) => _buildDoseCard(context, dose, lang, isRtl))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseCard(
    BuildContext context,
    MedicationDose dose,
    String lang,
    bool isRtl,
  ) {
    final med = dose.medication;
    final isTaken = dose.status == MedicationLogStatus.taken;
    final isSkipped = dose.status == MedicationLogStatus.skipped;
    final isDone = isTaken || isSkipped;

    final accentColor = _getAccentColor(med.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color:
            isDone ? AppColors.background.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored Accent Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4.w,
              decoration: BoxDecoration(
                color: isDone ? AppColors.textHint : accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12.w),

            // Medication Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          isDone ? AppColors.textHint : AppColors.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                    child: Text(med.getName(lang)),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${med.dose} ${med.getTypeLabel(lang).toLowerCase()}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (med.purpose != null && med.purpose!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      med.getPurpose(lang) ?? '',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            if (!isDone) ...[
              AnimatedActionButton(
                icon: Icons.check,
                backgroundColor: AppColors.primary,
                size: 44.w,
                onTap: () => context.read<MedicationCubit>().markAsTaken(
                      med.id,
                      dose.time,
                      med.name,
                    ),
              ),
              SizedBox(width: 8.w),
              AnimatedActionButton(
                icon: Icons.close,
                backgroundColor: AppColors.lightGrey,
                iconColor: AppColors.textHint,
                size: 36.w,
                onTap: () => context.read<MedicationCubit>().markAsSkipped(
                      med.id,
                      dose.time,
                      med.name,
                    ),
              ),
            ] else ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: isTaken
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.lightGrey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTaken ? Icons.check : Icons.remove,
                  color: isTaken ? AppColors.success : AppColors.textHint,
                  size: 24.sp,
                ),
              ),
            ],
            SizedBox(width: 8.w),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationListItem(
    BuildContext context,
    MedicationModel med,
    String lang,
    bool isRtl,
  ) {
    final frequencyText = _getFrequencyText(med, lang);
    final timeText = med.times.isNotEmpty ? _formatTime(med.times.first) : '';
    final isSelected = _selectedMedications.contains(med.id);

    return TapScaleWidget(
      scaleValue: 0.98,
      onTap: () {
        // ✅ In selection mode, toggle selection instead of navigation
        if (_isSelectionMode) {
          _toggleSelection(med.id);
        } else {
          Navigator.push(
            context,
            AppPageTransitions.fadeSlide(
              MedicationDetailsScreen(medication: med),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              if (_isSelectionMode) {
                _toggleSelection(med.id);
              } else {
                Navigator.push(
                  context,
                  AppPageTransitions.fadeSlide(
                    MedicationDetailsScreen(medication: med),
                  ),
                );
              }
            },
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // ✅ Checkbox in selection mode
                  if (_isSelectionMode) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textHint,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              color: AppColors.white, size: 16.sp)
                          : null,
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      MedicationModel.getTypeIcon(med.type),
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.getName(lang),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '$frequencyText${timeText.isNotEmpty ? ' • $timeText' : ''}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isSelectionMode)
                    Icon(
                      isRtl ? Icons.chevron_left : Icons.chevron_right,
                      color: AppColors.textHint,
                      size: 24.sp,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAccentColor(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return AppColors.primary;
      case MedicationType.capsule:
        return Colors.orange;
      case MedicationType.liquid:
        return Colors.blue;
      case MedicationType.injection:
        return Colors.red;
      case MedicationType.drops:
        return Colors.teal;
      case MedicationType.cream:
        return Colors.purple;
      case MedicationType.other:
        return Colors.grey;
    }
  }

  String _getFrequencyText(MedicationModel med, String lang) {
    switch (med.frequency) {
      case MedicationFrequency.daily:
        return lang == 'ar' ? 'يومياً' : 'Daily';
      case MedicationFrequency.specificDays:
        return lang == 'ar' ? 'أيام محددة' : 'Specific days';
      case MedicationFrequency.asNeeded:
        return lang == 'ar' ? 'عند الحاجة' : 'As needed';
    }
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
