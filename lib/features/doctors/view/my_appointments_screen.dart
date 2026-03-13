import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/features/home/view/home_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../model/appointment_model.dart';
import '../viewmodel/appointments_cubit.dart';
import '../viewmodel/appointments_state.dart';
import 'doctor_details_screen.dart';
import '../../../services/firestore/doctor_service.dart'; // import added
import '../viewmodel/appointments_state.dart';
import 'doctor_details_screen.dart';
import 'doctors_list_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/firestore/supabase_storage_service.dart';
import '../../../core/constants/supabase_storage.dart'; // import added

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppointmentsCubit>().loadAppointments();
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
        return BlocConsumer<AppointmentsCubit, AppointmentsState>(
          listener: (context, state) {
            if (state is AppointmentCancelled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('my_appointments.cancelled_success'.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          builder: (context, state) {
            if (isLarge) {
              return _buildDesktopLayout(context, state, lang);
            }
            return _buildMobileLayout(context, state, lang);
          },
        );
      },
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(
      BuildContext context, AppointmentsState state, String lang) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.logo, height: 120),
                  const SizedBox(height: 24),
                  const Text(
                    'Sanadi',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  _buildContent(context, state, lang, isDesktop: true),
                  Positioned(
                    top: 24,
                    left: 24,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Positioned(
                    top: 24,
                    right: 24,
                    child: LanguageButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(
      BuildContext context, AppointmentsState state, String lang) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'my_appointments.title'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildContent(context, state, lang, isDesktop: false),
      ),
    );
  }

  // Content
  Widget _buildContent(
      BuildContext context, AppointmentsState state, String lang,
      {required bool isDesktop}) {
    final cubit = context.read<AppointmentsCubit>();

    return Column(
      children: [
        // Date Selector with Light Blue Background
        Container(
          color: Colors.lightBlue.shade50,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : 16.w,
            vertical: isDesktop ? 24 : 16.h,
          ),
          child: Column(
            children: [
              if (isDesktop) ...[
                Text(
                  'my_appointments.title'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Date Selector
              _buildDateSelector(cubit, isDesktop),
            ],
          ),
        ),

        SizedBox(height: isDesktop ? 24 : 16.h),

        // Status Filter
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 16.w),
          child: _buildStatusFilter(cubit, isDesktop),
        ),

        SizedBox(height: isDesktop ? 16 : 12.h),

        // Appointments List
        Expanded(
          child: _buildAppointmentsList(context, state, lang, isDesktop),
        ),
      ],
    );
  }

  // ============================================
  // Date Selector - مطابق للتصميم في الصورة
  // ============================================
  Widget _buildDateSelector(AppointmentsCubit cubit, bool isDesktop) {
    final dates = cubit.getWeekDates(days: 7);
    final selectedDate = cubit.selectedDate;
    final lang = context.locale.languageCode;

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayNamesAr = [
      'اثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
      'جمعة',
      'سبت',
      'أحد'
    ];

    return SizedBox(
      height: isDesktop ? 85 : 75.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: isDesktop ? 12 : 10.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            // All Option
            final isSelected = selectedDate == null;
            return GestureDetector(
              onTap: () => cubit.selectAll(),
              child: Container(
                width: isDesktop ? 70 : 60.w,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color:
                          isSelected ? AppColors.white : AppColors.textPrimary,
                      size: isDesktop ? 26 : 24.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'All', // يمكنك استبدالها بـ 'general.all'.tr() إذا أضفت المفتاح
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 12.sp,
                        color: isSelected ? AppColors.white : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final date = dates[index - 1];
          final isSelected = selectedDate != null &&
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          // weekday: 1=Monday, 7=Sunday
          final weekdayIndex = date.weekday - 1;
          final dayName = lang == 'ar'
              ? dayNamesAr[weekdayIndex >= 0 ? weekdayIndex : 6]
              : dayNames[weekdayIndex >= 0 ? weekdayIndex : 6];

          return GestureDetector(
            onTap: () => cubit.selectDate(date),
            child: Container(
              width: isDesktop ? 70 : 60.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: isDesktop ? 26 : 24.sp,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 12.sp,
                      color: isSelected ? AppColors.white : AppColors.primary,
                      fontWeight: FontWeight.w500,
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

  // ============================================
  // Status Filter - مطابق للتصميم في الصورة
  // ============================================
  Widget _buildStatusFilter(AppointmentsCubit cubit, bool isDesktop) {
    final selectedStatus = cubit.selectedStatus;

    return Row(
      children: [
        _buildStatusChip(
          label: 'my_appointments.upcoming'.tr(),
          isSelected: selectedStatus == AppointmentStatus.upcoming,
          onTap: () => cubit.selectStatus(AppointmentStatus.upcoming),
          isDesktop: isDesktop,
        ),
        SizedBox(width: isDesktop ? 12 : 10.w),
        _buildStatusChip(
          label: 'my_appointments.completed'.tr(),
          isSelected: selectedStatus == AppointmentStatus.completed,
          onTap: () => cubit.selectStatus(AppointmentStatus.completed),
          isDesktop: isDesktop,
        ),
        SizedBox(width: isDesktop ? 12 : 10.w),
        _buildStatusChip(
          label: 'my_appointments.cancelled'.tr(),
          isSelected: selectedStatus == AppointmentStatus.cancelled,
          onTap: () => cubit.selectStatus(AppointmentStatus.cancelled),
          isDesktop: isDesktop,
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 22 : 18.w,
          vertical: isDesktop ? 10 : 9.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ============================================
  // Appointments List
  // ============================================
  Widget _buildAppointmentsList(BuildContext context, AppointmentsState state,
      String lang, bool isDesktop) {
    if (state is AppointmentsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is AppointmentsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: isDesktop ? 64 : 48.sp, color: AppColors.error),
            SizedBox(height: isDesktop ? 16 : 12.h),
            Text(
              state.message,
              style: TextStyle(
                  fontSize: isDesktop ? 14 : 13.sp,
                  color: AppColors.textSecondary),
            ),
            SizedBox(height: isDesktop ? 16 : 12.h),
            ElevatedButton(
              onPressed: () =>
                  context.read<AppointmentsCubit>().loadAppointments(),
              child: Text('general.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is AppointmentsEmpty ||
        (state is AppointmentsLoaded && state.appointments.isEmpty)) {
      return _buildEmptyState(context, isDesktop);
    }

    if (state is AppointmentsLoaded) {
      return ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 16.w,
          vertical: isDesktop ? 8 : 8.h,
        ),
        itemCount: state.appointments.length,
        separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 16 : 12.h),
        itemBuilder: (context, index) {
          final appointment = state.appointments[index];
          return _buildAppointmentCard(context, appointment, lang, isDesktop);
        },
      );
    }

    return const SizedBox();
  }

  // ============================================
  // Empty State
  // ============================================
  Widget _buildEmptyState(BuildContext context, bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: isDesktop ? 80 : 64.sp,
            color: AppColors.lightGrey,
          ),
          SizedBox(height: isDesktop ? 16 : 12.h),
          Text(
            'my_appointments.no_appointments'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: isDesktop ? 24 : 16.h),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorsListScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 24.w,
                vertical: isDesktop ? 12 : 10.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'doctor_details.book_appointment'.tr(),
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13.sp,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Appointment Card - مطابق للتصميم 100%
  // ============================================
  Widget _buildAppointmentCard(BuildContext context,
      AppointmentModel appointment, String lang, bool isDesktop) {
    final cubit = context.read<AppointmentsCubit>();
    final isUpcoming = appointment.status == AppointmentStatus.upcoming;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Time Column - على اليسار
          SizedBox(
            width: isDesktop ? 75 : 65.w,
            child: Text(
              appointment.getFormattedTime(),
              style: TextStyle(
                fontSize: isDesktop ? 15 : 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Blue Vertical Line
          Container(
            width: 4,
            height: isDesktop ? 90 : 80.h,
            margin: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 12.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Doctor Info Container - خلفية بيضاء
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Avatar & Name Row
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: isDesktop ? 50 : 45.w,
                        height: isDesktop ? 50 : 45.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: (appointment.doctorImage != null &&
                                    appointment.doctorImage!.isNotEmpty)
                                ? (appointment.doctorImage!.startsWith('http')
                                    ? appointment.doctorImage!
                                    : SupabaseStorageService.getDoctorImage(
                                        appointment.doctorImage!))
                                : SupabaseStorage.getDoctorImageByName(
                                    appointment.doctorName['en'] ?? ''),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(
                              Icons.person,
                              color: Colors.grey.shade400,
                              size: isDesktop ? 26 : 24.sp,
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person,
                              color: Colors.grey.shade400,
                              size: isDesktop ? 26 : 24.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isDesktop ? 12 : 10.w),
                      // Name & Specialty
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.getDoctorName(lang),
                              style: TextStyle(
                                fontSize: isDesktop ? 16 : 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              appointment.getSpecialty(lang),
                              style: TextStyle(
                                fontSize: isDesktop ? 13 : 12.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isDesktop ? 14 : 12.h),

                  // Action Buttons Row
                  Row(
                    children: [
                      // View Button (Blue Filled)
                      // View Button (Blue Filled)
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );

                            try {
                              final doctorService = DoctorService();
                              final doctor = await doctorService
                                  .getDoctorById(appointment.doctorId);

                              if (context.mounted) {
                                Navigator.pop(context); // Close loading

                                if (doctor != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DoctorDetailsScreen(doctor: doctor),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'my_appointments.doctor_not_found'.tr()),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // Close loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('general.error_occurred'.tr()),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 10 : 9.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'my_appointments.view'.tr(),
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (isUpcoming) SizedBox(width: isDesktop ? 10 : 8.w),

                      // Cancel Button (Red Outlined) - Only for Upcoming
                      if (isUpcoming)
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _showCancelDialog(context, appointment, cubit),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 10 : 9.h),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.error, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  'my_appointments.cancel'.tr(),
                                  style: TextStyle(
                                    fontSize: isDesktop ? 14 : 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cancel Dialog
  void _showCancelDialog(BuildContext context, AppointmentModel appointment,
      AppointmentsCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('my_appointments.cancel'.tr()),
        content: Text('my_appointments.cancel_confirm'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.cancelAppointment(appointment.id);
            },
            child: Text(
              'my_appointments.cancel'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
