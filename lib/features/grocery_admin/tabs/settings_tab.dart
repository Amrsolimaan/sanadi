import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_cubit.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_state.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final canManagePermissions =
            state is AdminLoaded && state.currentAdmin.canManageAdmins();

        return SingleChildScrollView(
          padding: EdgeInsets.all(isLarge ? 24 : 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.settings'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 24 : 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: isLarge ? 24 : 20.h),

              // Language Section
              _buildSettingsSection(
                context: context,
                title: 'admin.language'.tr(),
                icon: Icons.language,
                color: const Color(0xFF00BCD4),
                isLarge: isLarge,
                child: _buildLanguageSelector(context, lang, isLarge),
              ),
              SizedBox(height: isLarge ? 20 : 16.h),

              // Permissions Section (Super Admin only)
              if (canManagePermissions) ...[
                _buildSettingsSection(
                  context: context,
                  title: 'admin.permissions'.tr(),
                  icon: Icons.security,
                  color: const Color(0xFF9C27B0),
                  isLarge: isLarge,
                  child: _buildPermissionsInfo(context, isLarge, lang),
                ),
                SizedBox(height: isLarge ? 20 : 16.h),
              ],

              // Backup Section
              _buildSettingsSection(
                context: context,
                title: 'admin.backup'.tr(),
                icon: Icons.backup,
                color: const Color(0xFF4CAF50),
                isLarge: isLarge,
                child: _buildBackupOptions(context, isLarge),
              ),
              SizedBox(height: isLarge ? 20 : 16.h),

              // App Settings Section
              _buildSettingsSection(
                context: context,
                title: 'admin.app_settings'.tr(),
                icon: Icons.settings,
                color: const Color(0xFF2196F3),
                isLarge: isLarge,
                child: _buildAppSettings(context, isLarge),
              ),
              SizedBox(height: isLarge ? 20 : 16.h),

              // About Section
              _buildSettingsSection(
                context: context,
                title: 'admin.about'.tr(),
                icon: Icons.info_outline,
                color: const Color(0xFFFF9800),
                isLarge: isLarge,
                child: _buildAboutInfo(context, isLarge),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isLarge,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16.w),
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
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isLarge ? 24 : 22.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: isLarge ? 18 : 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 20 : 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
      BuildContext context, String currentLang, bool isLarge) {
    return Column(
      children: [
        _buildLanguageOption(
          context: context,
          flag: '🇺🇸',
          name: 'English',
          code: 'en',
          isSelected: currentLang == 'en',
          isLarge: isLarge,
        ),
        SizedBox(height: 8.h),
        _buildLanguageOption(
          context: context,
          flag: '🇪🇬',
          name: 'العربية',
          code: 'ar',
          isSelected: currentLang == 'ar',
          isLarge: isLarge,
        ),
      ],
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String flag,
    required String name,
    required String code,
    required bool isSelected,
    required bool isLarge,
  }) {
    return InkWell(
      onTap: () => context.setLocale(Locale(code)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: isLarge ? 24 : 22.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: isLarge ? 16 : 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: AppColors.primary, size: isLarge ? 24 : 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsInfo(
      BuildContext context, bool isLarge, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang == 'ar' ? 'جدول الصلاحيات:' : 'Permissions Table:',
          style: TextStyle(
              fontSize: isLarge ? 14 : 13.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 16.h),
        _buildPermissionRow(
            'admin.permission_view'.tr(), true, true, true, isLarge),
        _buildPermissionRow(
            'admin.permission_add'.tr(), false, true, true, isLarge),
        _buildPermissionRow(
            'admin.permission_edit'.tr(), false, true, true, isLarge),
        _buildPermissionRow(
            'admin.permission_delete'.tr(), false, true, true, isLarge),
        _buildPermissionRow(
            'admin.permission_manage_users'.tr(), false, false, true, isLarge),
        _buildPermissionRow(
            'admin.permission_manage_admins'.tr(), false, false, true, isLarge),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem('Moderator', Colors.orange, isLarge),
            SizedBox(width: 16.w),
            _buildLegendItem('Admin', Colors.blue, isLarge),
            SizedBox(width: 16.w),
            _buildLegendItem('Super Admin', Colors.purple, isLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionRow(
      String permission, bool mod, bool admin, bool superAdmin, bool isLarge) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(permission,
                  style: TextStyle(fontSize: isLarge ? 13 : 12.sp))),
          Expanded(
              child: Center(
                  child: Icon(mod ? Icons.check_circle : Icons.cancel,
                      color: mod ? Colors.orange : AppColors.lightGrey,
                      size: isLarge ? 20 : 18.sp))),
          Expanded(
              child: Center(
                  child: Icon(admin ? Icons.check_circle : Icons.cancel,
                      color: admin ? Colors.blue : AppColors.lightGrey,
                      size: isLarge ? 20 : 18.sp))),
          Expanded(
              child: Center(
                  child: Icon(superAdmin ? Icons.check_circle : Icons.cancel,
                      color: superAdmin ? Colors.purple : AppColors.lightGrey,
                      size: isLarge ? 20 : 18.sp))),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isLarge) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4.w),
        Text(label,
            style: TextStyle(
                fontSize: isLarge ? 11 : 10.sp,
                color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildBackupOptions(BuildContext context, bool isLarge) {
    return Column(
      children: [
        _buildOptionTile(
          icon: Icons.cloud_download,
          title: 'admin.export_data'.tr(),
          subtitle: 'Export all data to JSON/CSV',
          color: const Color(0xFF4CAF50),
          isLarge: isLarge,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export feature coming soon'))),
        ),
        SizedBox(height: 8.h),
        _buildOptionTile(
          icon: Icons.cloud_upload,
          title: 'admin.import_data'.tr(),
          subtitle: 'Import data from backup file',
          color: const Color(0xFF2196F3),
          isLarge: isLarge,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Import feature coming soon'))),
        ),
      ],
    );
  }

  Widget _buildAppSettings(BuildContext context, bool isLarge) {
    return Column(
      children: [
        _buildSwitchTile(
            icon: Icons.notifications,
            title: 'admin.notifications'.tr(),
            value: true,
            isLarge: isLarge,
            onChanged: (v) {}),
        SizedBox(height: 8.h),
        _buildOptionTile(
            icon: Icons.palette,
            title: 'admin.theme'.tr(),
            subtitle: 'Light Mode',
            color: const Color(0xFF9C27B0),
            isLarge: isLarge,
            onTap: () {}),
      ],
    );
  }

  Widget _buildAboutInfo(BuildContext context, bool isLarge) {
    return Column(
      children: [
        _buildInfoRow('admin.version'.tr(), '1.0.0', isLarge),
        SizedBox(height: 8.h),
        _buildInfoRow('Build', '2025.01.10', isLarge),
        SizedBox(height: 8.h),
        _buildInfoRow('Developer', 'Amr', isLarge),
      ],
    );
  }

  Widget _buildOptionTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required bool isLarge,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: isLarge ? 20 : 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: isLarge ? 14 : 13.sp,
                          fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: isLarge ? 12 : 11.sp,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16.sp, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      {required IconData icon,
      required String title,
      required bool value,
      required bool isLarge,
      required ValueChanged<bool> onChanged}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon,
                color: AppColors.primary, size: isLarge ? 20 : 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: isLarge ? 14 : 13.sp,
                      fontWeight: FontWeight.w500))),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isLarge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp,
                color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
