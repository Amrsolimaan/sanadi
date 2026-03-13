import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // ============================================
  // App Configuration - يمكن تعديلها لاحقاً
  // ============================================
  static const String appVersion = '1.0.0';
  static const String? developerName = null; // أضف اسم المطور لاحقاً
  static const String? developerEmail = null; // أضف إيميل المطور لاحقاً
  static const String? websiteUrl = null; // أضف رابط الموقع لاحقاً
  static const String? privacyPolicyUrl = null; // أضف رابط السياسة لاحقاً
  static const String? termsUrl = null; // أضف رابط الشروط لاحقاً

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
          'about.title'.tr(),
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
              // Logo & App Name
              _buildAppHeader(isArabic),

              SizedBox(height: 32.h),

              // App Description
              _buildDescriptionCard(isArabic),

              SizedBox(height: 24.h),

              // Features List
              _buildFeaturesCard(isArabic),

              SizedBox(height: 24.h),

              // Coming Soon
              _buildComingSoonCard(isArabic),

              SizedBox(height: 24.h),

              // Developer Info (if available)
              if (_hasDeveloperInfo()) _buildDeveloperCard(context, isArabic),

              // Links (if available)
              if (_hasLinks()) ...[
                SizedBox(height: 24.h),
                _buildLinksCard(context, isArabic),
              ],

              SizedBox(height: 32.h),

              // Version Info
              _buildVersionInfo(isArabic),
            ],
          ),
        ),
      ),
    );
  }

  /// Header مع اللوجو واسم التطبيق
  Widget _buildAppHeader(bool isArabic) {
    return Column(
      children: [
        // Logo Container
        Container(
          width: 100.w,
          height: 100.w,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 16.h),
        // App Name
        Text(
          isArabic ? 'سندي' : 'Sanadi',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'about.tagline'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// بطاقة الوصف
  Widget _buildDescriptionCard(bool isArabic) {
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
                Icons.info_outline,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'about.about_app'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'about.description'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة المميزات
  Widget _buildFeaturesCard(bool isArabic) {
    final features = [
      {'icon': Icons.medical_services, 'key': 'about.feature_doctors'},
      {'icon': Icons.medication, 'key': 'about.feature_medications'},
      {'icon': Icons.emergency, 'key': 'about.feature_emergency'},
      {'icon': Icons.favorite, 'key': 'about.feature_health'},
      {'icon': Icons.fitness_center, 'key': 'about.feature_exercises'},
      {'icon': Icons.location_on, 'key': 'about.feature_location'},
      {'icon': Icons.shopping_cart, 'key': 'about.feature_shopping'},
    ];

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
                Icons.star,
                color: AppColors.logoOrange,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'about.features'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...features.map((feature) => _buildFeatureItem(
                icon: feature['icon'] as IconData,
                text: (feature['key'] as String).tr(),
              )),
        ],
      ),
    );
  }

  /// عنصر ميزة
  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة قريباً
  Widget _buildComingSoonCard(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.logoOrange.withOpacity(0.1),
            AppColors.logoYellow.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.logoOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch,
                color: AppColors.logoOrange,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'about.coming_soon'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildComingSoonItem(
            icon: Icons.local_pharmacy,
            text: 'about.coming_pharmacy'.tr(),
          ),
          _buildComingSoonItem(
            icon: Icons.cleaning_services,
            text: 'about.coming_household'.tr(),
          ),
           _buildComingSoonItem(
            icon: Icons.face,
            text: 'about.coming_personal_care'.tr(),
          ),
          _buildComingSoonItem(
            icon: Icons.delivery_dining,
            text: 'about.coming_delivery'.tr(),
          ),
        ],
      ),
    );
  }

  /// عنصر قريباً
  Widget _buildComingSoonItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.logoGreen,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة معلومات المطور (اختياري)
  Widget _buildDeveloperCard(BuildContext context, bool isArabic) {
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
                Icons.code,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'about.developer'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (developerName != null)
            _buildInfoRow(Icons.person, developerName!),
          if (developerEmail != null) ...[
            SizedBox(height: 8.h),
            InkWell(
              onTap: () => _launchEmail(developerEmail!),
              child: _buildInfoRow(Icons.email, developerEmail!, isLink: true),
            ),
          ],
        ],
      ),
    );
  }

  /// بطاقة الروابط (اختياري)
  Widget _buildLinksCard(BuildContext context, bool isArabic) {
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
                Icons.link,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'about.links'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (websiteUrl != null)
            _buildLinkItem(
              context,
              icon: Icons.language,
              label: 'about.website'.tr(),
              url: websiteUrl!,
            ),
          if (privacyPolicyUrl != null)
            _buildLinkItem(
              context,
              icon: Icons.privacy_tip,
              label: 'about.privacy_policy'.tr(),
              url: privacyPolicyUrl!,
            ),
          if (termsUrl != null)
            _buildLinkItem(
              context,
              icon: Icons.description,
              label: 'about.terms'.tr(),
              url: termsUrl!,
            ),
        ],
      ),
    );
  }

  /// عنصر رابط
  Widget _buildLinkItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.open_in_new,
              color: AppColors.textHint,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  /// صف معلومات
  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: isLink ? AppColors.primary : AppColors.textSecondary,
            decoration: isLink ? TextDecoration.underline : null,
          ),
        ),
      ],
    );
  }

  /// معلومات الإصدار
  Widget _buildVersionInfo(bool isArabic) {
    return Column(
      children: [
        Text(
          '${'about.version'.tr()} $appVersion',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '© ${DateTime.now().year} Sanadi',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textHint,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'about.made_with_love'.tr(),
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  /// التحقق من وجود معلومات المطور
  bool _hasDeveloperInfo() {
    return developerName != null || developerEmail != null;
  }

  /// التحقق من وجود روابط
  bool _hasLinks() {
    return websiteUrl != null || privacyPolicyUrl != null || termsUrl != null;
  }

  /// فتح رابط
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// فتح الإيميل
  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
