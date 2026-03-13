import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  final String doctorId;
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.appointmentData,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final status = appointmentData['status'] ?? 'upcoming';
    final date = appointmentData['date'] ?? '';
    final time = appointmentData['time'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'admin.appointment_details'.tr(),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _updateStatus(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'upcoming', child: Text('admin.status_upcoming'.tr())),
              PopupMenuItem(value: 'completed', child: Text('admin.status_completed'.tr())),
              PopupMenuItem(value: 'cancelled', child: Text('admin.status_cancelled'.tr(), style: const TextStyle(color: AppColors.error))),
            ],
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(status, date, time, lang),
            SizedBox(height: 16.h),

            // Doctor Info
            if (doctorId.isNotEmpty)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('doctor').doc(doctorId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: AppColors.lightGrey,
                            child: Icon(Icons.person, size: 35, color: AppColors.textHint),
                          ),
                          SizedBox(width: 16.w),
                          Text('Doctor info unavailable', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  final doctorData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  return _buildDoctorCard(doctorData, lang);
                },
              )
            else
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppColors.lightGrey,
                      child: Icon(Icons.person, size: 35, color: AppColors.textHint),
                    ),
                    SizedBox(width: 16.w),
                    Text('No doctor assigned', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            SizedBox(height: 16.h),

            // Patient Info
            _buildSectionCard(
              title: 'admin.patient_info'.tr(),
              icon: Icons.person,
              children: [
                _buildInfoRow('admin.customer_name'.tr(), appointmentData['patientName'] ?? appointmentData['userName'] ?? '-'),
                _buildInfoRow('admin.customer_phone'.tr(), appointmentData['patientPhone'] ?? appointmentData['userPhone'] ?? '-'),
                if (appointmentData['notes'] != null && appointmentData['notes'].toString().isNotEmpty)
                  _buildInfoRow('grocery.notes'.tr(), appointmentData['notes']),
              ],
            ),
            SizedBox(height: 16.h),

            // Appointment Details
            _buildSectionCard(
              title: 'admin.appointment_details'.tr(),
              icon: Icons.calendar_today,
              children: [
                _buildInfoRow('admin.appointment_date'.tr(), date),
                _buildInfoRow('admin.appointment_time'.tr(), time),
                _buildInfoRow('admin.appointment_status'.tr(), _getStatusText(status)),
                if (appointmentData['type'] != null)
                  _buildInfoRow('Type', appointmentData['type']),
              ],
            ),
            SizedBox(height: 24.h),

            // Action Buttons
            if (status == 'upcoming') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRescheduleDialog(context),
                      icon: const Icon(Icons.schedule),
                      label: Text('admin.reschedule'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, 'completed'),
                      icon: const Icon(Icons.check),
                      label: Text('admin.mark_completed'.tr()),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context),
                  icon: const Icon(Icons.cancel),
                  label: Text('admin.cancel_appointment'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String date, String time, String lang) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.schedule;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: AppColors.white, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '$date - $time',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctorData, String lang) {
    final name = lang == 'ar'
        ? (doctorData['nameAr'] ?? doctorData['nameEn'] ?? 'Unknown')
        : (doctorData['nameEn'] ?? doctorData['nameAr'] ?? 'Unknown');
    final specialty = lang == 'ar'
        ? (doctorData['specialtyAr'] ?? doctorData['specialtyEn'] ?? '')
        : (doctorData['specialtyEn'] ?? doctorData['specialtyAr'] ?? '');
    final imageUrl = doctorData['imageUrl'] ?? '';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl.isEmpty ? const Icon(Icons.person, size: 35) : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.doctor_info'.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '${doctorData['rating'] ?? 0}',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.workspace_premium, color: AppColors.primary, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '${doctorData['points'] ?? 0} pts',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'admin.status_completed'.tr();
      case 'cancelled':
        return 'admin.status_cancelled'.tr();
      default:
        return 'admin.status_upcoming'.tr();
    }
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctor')
          .doc(doctorId)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.save_success'.tr())),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.error'.tr()), backgroundColor: AppColors.error),
      );
    }
  }

  void _showRescheduleDialog(BuildContext context) {
    // TODO: Implement reschedule dialog with date/time picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reschedule feature coming soon')),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('admin.cancel_appointment'.tr()),
        content: Text('admin.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(context, 'cancelled');
            },
            child: Text(
              'general.delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
