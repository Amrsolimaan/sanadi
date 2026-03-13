import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/core/localization/language_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import '../viewmodel/profile_cubit.dart';
import 'personal_details_screen.dart';
import 'address_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'notification_history_screen.dart';
import '../../favorites/view/favorites_screen.dart';
import '../../medications/viewmodel/medication_cubit.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ✅ key لتحديث الصورة فوراً
  Key _imageKey = UniqueKey();

  void _refreshImage() {
    setState(() {
      _imageKey = UniqueKey();
    });
  }

  Future<void> _clearImageCache(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      await CachedNetworkImage.evictFromCache(imageUrl);
      final baseUrl = imageUrl.split('?').first;
      await CachedNetworkImage.evictFromCache(baseUrl);
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              title: Text(
                'nav.profile'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: true,
            )
          : null,
      // ✅ BlocListener للـ ProfileCubit
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileImageUploaded) {
            _clearImageCache(state.imageUrl);
            _refreshImage();
          }
          // ✅ عند حذف الصورة
          if (state is ProfileImageDeleted) {
            _clearImageCache(state.deletedImageUrl);
            _refreshImage();
          }
          if (state is ProfileUpdated) {
            _refreshImage();
          }
          if (state is ProfileLoaded) {
            _refreshImage();
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            String userName = 'User';
            String userEmail = '';
            String? profileImage;

            if (authState is AuthSuccess) {
              userName = authState.user.fullName;
              userEmail = authState.user.email;
              profileImage = authState.user.profileImage;
            }

            // ✅ استخدام الصورة من ProfileState إذا كانت أحدث
            final profileState = context.watch<ProfileCubit>().state;
            if (profileState is ProfileLoaded) {
              profileImage = profileState.user.profileImage;
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  if (!widget.showAppBar) ...[
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Text(
                          'profile.title'.tr(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Profile Image
                  _buildProfileImage(context, profileImage),
                  SizedBox(height: 16.h),

                  // User Name
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // User Email
                  if (userEmail.isNotEmpty)
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),

                  SizedBox(height: 32.h),

                  // Menu Items
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF4A90E2),
                    iconBgColor: const Color(0xFF4A90E2).withOpacity(0.1),
                    label: 'profile.personal_details'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalDetailsScreen(),
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF50C878),
                    iconBgColor: const Color(0xFF50C878).withOpacity(0.1),
                    label: 'profile.address'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressScreen(),
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.favorite_outline,
                    iconColor: const Color(0xFFE91E63),
                    iconBgColor: const Color(0xFFE91E63).withOpacity(0.1),
                    label: 'profile.favorites'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF9C27B0),
                    iconBgColor: const Color(0xFF9C27B0).withOpacity(0.1),
                    label: 'profile.about'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFFFF9800),
                    iconBgColor: const Color(0xFFFF9800).withOpacity(0.1),
                    label: 'profile.help'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpScreen(),
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.language,
                    iconColor: const Color(0xFF00BCD4),
                    iconBgColor: const Color(0xFF00BCD4).withOpacity(0.1),
                    label: 'profile.language'.tr(),
                    onTap: () => _showLanguageDialog(context),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none_outlined,
                    iconColor: const Color(0xFFFF5722),
                    iconBgColor: const Color(0xFFFF5722).withOpacity(0.1),
                    label: 'profile.notification_history'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationHistoryScreen(),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.error,
                      ),
                      label: Text(
                        'auth.logout'.tr(),
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 16.sp,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// بناء صورة البروفايل
  Widget _buildProfileImage(BuildContext context, String? profileImage) {
    return Container(
      key: _imageKey, // ✅ key فريد
      width: 100.w,
      height: 100.w, // ✅ استخدام .w لكليهما
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        image: profileImage != null && profileImage.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(profileImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: profileImage == null || profileImage.isEmpty
          ? Icon(
              Icons.person,
              size: 50.sp,
              color: AppColors.primary,
            )
          : null,
    );
  }

  /// بناء عنصر القائمة
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          width: 40.w,
          height: 40.w, // ✅ استخدام .w لكليهما
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22.sp,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: AppColors.textHint,
        ),
        onTap: onTap,
      ),
    );
  }

  /// عرض نافذة تغيير اللغة
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.locale.languageCode == 'ar'
            ? 'اختر اللغة'
            : 'Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () async {
                await context
                    .read<LanguageCubit>()
                    .changeLanguage(context, 'en');
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Language changed successfully')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Text('🇪🇬', style: TextStyle(fontSize: 24)),
              title: const Text('العربية'),
              onTap: () async {
                await context
                    .read<LanguageCubit>()
                    .changeLanguage(context, 'ar');
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تغيير اللغة بنجاح')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// عرض نافذة تأكيد تسجيل الخروج
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('auth.logout'.tr()),
        content: Text('auth.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Clear medication data locally
              context.read<MedicationCubit>().clear();
              // Perform sign out and cancel system alarms
              context.read<AuthCubit>().logout();
            },
            child: Text(
              'auth.logout'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
