import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // ============================================
  // Contact Configuration
  // ============================================
  static const String supportEmail = 'saanadiiii@gmail.com';
  static const String? youtubeChannel = null; // أضف رابط اليوتيوب لاحقاً

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

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
          'help.title'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Header
              _buildHeader(isArabic),

              SizedBox(height: 32.h),

              // Contact Us Card
              _buildContactCard(context, isArabic),

              SizedBox(height: 24.h),

              // User Guide Card
              _buildUserGuideCard(context, isArabic),

              SizedBox(height: 24.h),

              // FAQ Section
              _buildFAQCard(isArabic),

              SizedBox(height: 24.h),

              // Tips Card
              _buildTipsCard(isArabic),
            ],
          ),
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(bool isArabic) {
    return Column(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.support_agent,
            size: 40.sp,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'help.header_title'.tr(),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'help.header_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// بطاقة التواصل
  Widget _buildContactCard(BuildContext context, bool isArabic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(
                Icons.contact_mail,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'help.contact_us'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Email
          _buildContactItem(
            context,
            icon: Icons.email,
            iconColor: AppColors.error,
            iconBgColor: AppColors.error.withOpacity(0.1),
            title: 'help.email'.tr(),
            subtitle: supportEmail,
            onTap: () => _launchEmail(supportEmail),
          ),
        ],
      ),
    );
  }

  /// عنصر تواصل
  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة دليل المستخدم
  Widget _buildUserGuideCard(BuildContext context, bool isArabic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.05),
            AppColors.error.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_circle_fill,
                  color: AppColors.error,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'help.user_guide'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'help.user_guide_desc'.tr(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openYoutubeChannel(context, isArabic),
              icon: Icon(
                Icons.ondemand_video,
                color: AppColors.white,
                size: 20.sp,
              ),
              label: Text(
                'help.watch_tutorials'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الأسئلة الشائعة
  Widget _buildFAQCard(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(
                Icons.quiz,
                color: AppColors.logoOrange,
                size: 19.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'help.faq'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildFAQItem(
            question: 'help.faq1_q'.tr(),
            answer: 'help.faq1_a'.tr(),
          ),
          _buildFAQItem(
            question: 'help.faq2_q'.tr(),
            answer: 'help.faq2_a'.tr(),
          ),
          _buildFAQItem(
            question: 'help.faq3_q'.tr(),
            answer: 'help.faq3_a'.tr(),
          ),
          _buildFAQItem(
            question: 'help.faq4_q'.tr(),
            answer: 'help.faq4_a'.tr(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// عنصر سؤال وجواب
  Widget _buildFAQItem({
    required String question,
    required String answer,
    bool isLast = false,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.only(bottom: 12.h),
      title: Text(
        question,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.textHint,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// بطاقة النصائح
  Widget _buildTipsCard(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppColors.success,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'help.tips'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTipItem('help.tip1'.tr()),
          _buildTipItem('help.tip2'.tr()),
          _buildTipItem('help.tip3'.tr()),
        ],
      ),
    );
  }

  /// عنصر نصيحة - محدّث لحل مشكلة الـ Overflow
  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// فتح الإيميل
  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Sanadi App Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// فتح قناة اليوتيوب
  void _openYoutubeChannel(BuildContext context, bool isArabic) {
    if (youtubeChannel == null || youtubeChannel!.isEmpty) {
      // إظهار رسالة "قريباً"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.white),
              SizedBox(width: 8.w),
              Text(
                isArabic ? 'قريباً' : 'Coming Soon',
                style: const TextStyle(color: AppColors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.logoOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // فتح اليوتيوب
      _launchUrl(youtubeChannel!);
    }
  }

  /// فتح رابط
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
