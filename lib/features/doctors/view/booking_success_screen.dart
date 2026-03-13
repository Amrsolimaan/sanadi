import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/features/home/view/home_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/language_cubit.dart';
import '../model/doctor_model.dart';
import '../model/appointment_model.dart';
import 'my_appointments_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final AppointmentModel appointment;
  final DoctorModel doctor;

  const BookingSuccessScreen({
    super.key,
    required this.appointment,
    required this.doctor,
  });

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, languageState) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(isLarge ? 48 : 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Success Icon
                      Container(
                        width: isLarge ? 120 : 100.w,
                        height: isLarge ? 120 : 100.h,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: isLarge ? 60 : 50.sp,
                        ),
                      ),

                      SizedBox(height: isLarge ? 32 : 24.h),

                      // Congratulations
                      Text(
                        'booking_success.congratulations'.tr(),
                        style: TextStyle(
                          fontSize: isLarge ? 28 : 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      SizedBox(height: isLarge ? 8 : 6.h),

                      // Subtitle
                      Text(
                        'booking_success.appointment_booked'.tr(),
                        style: TextStyle(
                          fontSize: isLarge ? 16 : 14.sp,
                          color: AppColors.primary,
                        ),
                      ),

                      SizedBox(height: isLarge ? 48 : 32.h),

                      // Appointment Details
                      Container(
                        width: isLarge ? 400 : double.infinity,
                        padding: EdgeInsets.all(isLarge ? 24 : 20.w),
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
                          children: [
                            _buildDetailRow(
                              icon: Icons.person,
                              label: doctor.getName(lang),
                              isLarge: isLarge,
                            ),
                            SizedBox(height: isLarge ? 12 : 10.h),
                            _buildDetailRow(
                              icon: Icons.medical_services,
                              label: doctor.getSpecialty(lang),
                              isLarge: isLarge,
                            ),
                            SizedBox(height: isLarge ? 12 : 10.h),
                            _buildDetailRow(
                              icon: Icons.calendar_today,
                              label: appointment.getFormattedDate(),
                              isLarge: isLarge,
                            ),
                            SizedBox(height: isLarge ? 12 : 10.h),
                            _buildDetailRow(
                              icon: Icons.access_time,
                              label: appointment.getFormattedTime(),
                              isLarge: isLarge,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // View Appointments Button
                      SizedBox(
                        width: isLarge ? 400 : double.infinity,
                        height: isLarge ? 52 : 48.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyAppointmentsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'booking_success.view_appointments'.tr(),
                            style: TextStyle(
                              fontSize: isLarge ? 16 : 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isLarge ? 12 : 10.h),

                      // Back to Home Button
                      SizedBox(
                        width: isLarge ? 400 : double.infinity,
                        height: isLarge ? 52 : 48.h,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'booking_success.back_to_home'.tr(),
                            style: TextStyle(
                              fontSize: isLarge ? 16 : 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isLarge ? 24 : 16.h),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required bool isLarge,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: isLarge ? 22 : 20.sp,
        ),
        SizedBox(width: isLarge ? 12 : 10.w),
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 15 : 14.sp,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
