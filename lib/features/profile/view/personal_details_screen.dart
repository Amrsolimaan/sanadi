import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodel/profile_cubit.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import 'change_password_screen.dart';

// ✅ Helper للصور عالية الجودة
class SocialImageHelper {
  /// الحصول على صورة Google بجودة عالية
  static String getHighQualityGooglePhoto(String photoUrl) {
    if (photoUrl.contains('googleusercontent.com')) {
      final baseUrl = photoUrl.split('=')[0];
      return '$baseUrl=s500'; // 500x500 pixels
    }
    return photoUrl;
  }

  /// الحصول على صورة Facebook بجودة عالية
  static String getHighQualityFacebookPhoto(String photoUrl) {
    if (photoUrl.contains('facebook.com') || photoUrl.contains('fbcdn.net')) {
      return photoUrl
          .replaceAll('type=small', 'type=large')
          .replaceAll('type=normal', 'type=large')
          .replaceAll('width=50', 'width=500')
          .replaceAll('height=50', 'height=500');
    }
    return photoUrl;
  }

  /// تحسين جودة الصورة حسب المصدر
  static String getHighQualityPhoto(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';

    if (photoUrl.contains('googleusercontent.com')) {
      return getHighQualityGooglePhoto(photoUrl);
    } else if (photoUrl.contains('facebook.com') ||
        photoUrl.contains('fbcdn.net')) {
      return getHighQualityFacebookPhoto(photoUrl);
    }

    return photoUrl;
  }
}

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  Key _imageKey = UniqueKey();

  // Controllers للتعديل
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
      // مسح الصورة المحسنة أيضاً
      final highQualityUrl = SocialImageHelper.getHighQualityPhoto(imageUrl);
      await CachedNetworkImage.evictFromCache(highQualityUrl);
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          context.locale.languageCode == 'ar'
              ? 'البيانات الشخصية'
              : 'Personal Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state is ProfileImageUploaded) {
            _clearImageCache(state.imageUrl);
            _refreshImage();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.locale.languageCode == 'ar'
                    ? 'تم تحديث الصورة بنجاح'
                    : 'Profile image updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (state is ProfileImageDeleted) {
            _clearImageCache(state.deletedImageUrl);
            _refreshImage();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (state is ProfileUpdated) {
            _refreshImage();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (state is ProfileLoaded) {
            _refreshImage();
          }
        },
        builder: (context, profileState) {
          if (profileState is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              String userName = 'User';
              String userEmail = '';
              String userPhone = '';
              String? profileImage;

              if (authState is AuthSuccess) {
                userName = authState.user.fullName;
                userEmail = authState.user.email;
                userPhone = authState.user.phone;
                profileImage = authState.user.profileImage;
              }

              if (profileState is ProfileLoaded) {
                profileImage = profileState.user.profileImage;
              }

              final isUploading = profileState is ProfileImageUploading;

              return SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    // Profile Image
                    _buildProfileImageSection(
                      context,
                      profileImage,
                      isUploading,
                    ),

                    SizedBox(height: 32.h),

                    // Full Name Field - قابل للتعديل
                    _buildEditableInfoTile(
                      icon: Icons.person_outline,
                      label: context.locale.languageCode == 'ar'
                          ? 'الاسم الكامل'
                          : 'Full name',
                      value: userName,
                      onEdit: () => _showEditNameDialog(context, userName),
                    ),

                    SizedBox(height: 16.h),

                    // Email Field - للقراءة فقط
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: context.locale.languageCode == 'ar'
                          ? 'البريد الإلكتروني'
                          : 'Email',
                      value: userEmail,
                    ),

                    // Phone Field - يظهر فقط إذا كان موجود ويمكن تعديله
                    if (userPhone.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _buildEditableInfoTile(
                        icon: Icons.phone_outlined,
                        label: context.locale.languageCode == 'ar'
                            ? 'رقم الهاتف'
                            : 'Phone',
                        value: userPhone,
                        onEdit: () => _showEditPhoneDialog(context, userPhone),
                      ),
                    ],

                    SizedBox(height: 32.h),

                    // Change Password Button (only for email users)
                    if (context.read<ProfileCubit>().isEmailPasswordUser())
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.lock_outline),
                          label: Text(
                            context.locale.languageCode == 'ar'
                                ? 'تغيير كلمة المرور'
                                : 'Change password',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
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
          );
        },
      ),
    );
  }

  /// بناء قسم الصورة الشخصية
  Widget _buildProfileImageSection(
    BuildContext context,
    String? profileImage,
    bool isUploading,
  ) {
    // ✅ استخدام الصورة المحسنة
    final displayImage = profileImage != null && profileImage.isNotEmpty
        ? SocialImageHelper.getHighQualityPhoto(profileImage)
        : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: displayImage != null && !isUploading
              ? () => _showFullImage(context, profileImage!)
              : null,
          child: Hero(
            tag: 'profile_image',
            child: Container(
              key: _imageKey,
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                image: displayImage != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(displayImage),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: displayImage == null
                  ? Icon(
                      Icons.person,
                      size: 60.sp,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ),
        ),
        if (isUploading)
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
        if (!isUploading)
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: () => _showImageOptions(context, profileImage),
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 18.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// بناء عنصر معلومات للقراءة فقط
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر معلومات قابل للتعديل
  Widget _buildEditableInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog لتعديل الاسم
  void _showEditNameDialog(BuildContext context, String currentName) {
    _nameController.text = currentName;
    final lang = context.locale.languageCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'ar' ? 'تعديل الاسم' : 'Edit Name'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: lang == 'ar' ? 'الاسم الكامل' : 'Full Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang == 'ar'
                        ? 'الرجاء إدخال الاسم'
                        : 'Please enter name'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<ProfileCubit>().updateUserName(newName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(lang == 'ar' ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  /// Dialog لتعديل رقم الهاتف
  void _showEditPhoneDialog(BuildContext context, String currentPhone) {
    _phoneController.text = currentPhone;
    final lang = context.locale.languageCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'ar' ? 'تعديل رقم الهاتف' : 'Edit Phone'),
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: lang == 'ar' ? 'رقم الهاتف' : 'Phone Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPhone = _phoneController.text.trim();
              if (newPhone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang == 'ar'
                        ? 'الرجاء إدخال رقم الهاتف'
                        : 'Please enter phone number'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<ProfileCubit>().updateUserPhone(newPhone);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(lang == 'ar' ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  /// عرض الصورة بشكل كامل
  void _showFullImage(BuildContext context, String imageUrl) {
    // ✅ استخدام الصورة المحسنة
    final highQualityUrl = SocialImageHelper.getHighQualityPhoto(imageUrl);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Center(
                child: Hero(
                  tag: 'profile_image',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: highQualityUrl,
                      fit: BoxFit.contain,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 50.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              context.locale.languageCode == 'ar'
                                  ? 'فشل تحميل الصورة'
                                  : 'Failed to load image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16.h,
              right: 16.w,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض خيارات الصورة
  void _showImageOptions(BuildContext context, String? currentImage) {
    final lang = context.locale.languageCode;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              lang == 'ar' ? 'خيارات الصورة' : 'Photo Options',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            if (currentImage != null && currentImage.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.visibility, color: AppColors.primary),
                title: Text(lang == 'ar' ? 'عرض الصورة' : 'View Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFullImage(context, currentImage);
                },
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text(lang == 'ar' ? 'التقاط صورة' : 'Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ProfileCubit>().pickAndUploadImage(
                      ImageSource.camera,
                    );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(
                  lang == 'ar' ? 'اختيار من المعرض' : 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ProfileCubit>().pickAndUploadImage(
                      ImageSource.gallery,
                    );
              },
            ),
            if (currentImage != null && currentImage.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text(lang == 'ar' ? 'حذف الصورة' : 'Remove Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// تأكيد حذف الصورة
  void _showDeleteConfirmation(BuildContext context) {
    final lang = context.locale.languageCode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'ar' ? 'حذف الصورة' : 'Delete Photo'),
        content: Text(lang == 'ar'
            ? 'هل أنت متأكد من حذف صورة الملف الشخصي؟'
            : 'Are you sure you want to delete your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileCubit>().removeProfileImage();
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
}
