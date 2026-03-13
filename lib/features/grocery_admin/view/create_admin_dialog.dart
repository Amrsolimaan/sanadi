import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanadi/features/auth/model/user_model.dart';
import '../../../../core/constants/app_colors.dart';

class CreateAdminDialog extends StatefulWidget {
  final String creatorUid;

  const CreateAdminDialog({super.key, required this.creatorUid});

  @override
  State<CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.admin;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420.w,
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_add,
                          color: AppColors.primary, size: 28.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.create_admin'.tr(),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            lang == 'ar'
                                ? 'إنشاء حساب مدير جديد'
                                : 'Create a new admin account',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'admin.admin_name'.tr(),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'general.required'.tr();
                    if (v.trim().length < 3)
                      return 'validation.invalid_name'.tr();
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'admin.admin_email'.tr(),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'general.required'.tr();
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return 'validation.invalid_email'.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'admin.admin_phone'.tr(),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'general.required'.tr();
                    if (v.trim().length < 10)
                      return 'validation.invalid_phone'.tr();
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'admin.admin_password'.tr(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'general.required'.tr();
                    if (v.length < 8)
                      return 'validation.password_too_short'.tr();
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Role Selection
                Text(
                  'admin.admin_role'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGrey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildRoleOption(
                        role: UserRole.moderator,
                        title: 'admin.role_moderator'.tr(),
                        subtitle: lang == 'ar'
                            ? 'عرض البيانات فقط'
                            : 'View data only',
                        icon: Icons.visibility,
                        color: Colors.orange,
                      ),
                      const Divider(height: 1),
                      _buildRoleOption(
                        role: UserRole.admin,
                        title: 'admin.role_admin'.tr(),
                        subtitle: lang == 'ar'
                            ? 'إضافة وتعديل وحذف'
                            : 'Add, edit, delete',
                        icon: Icons.edit,
                        color: Colors.blue,
                      ),
                      const Divider(height: 1),
                      _buildRoleOption(
                        role: UserRole.superAdmin,
                        title: 'admin.role_super_admin'.tr(),
                        subtitle:
                            lang == 'ar' ? 'كل الصلاحيات' : 'All permissions',
                        icon: Icons.admin_panel_settings,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Warning
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: AppColors.warning, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          lang == 'ar'
                              ? 'سيتمكن هذا المستخدم من الوصول للوحة التحكم'
                              : 'This user will have access to the admin dashboard',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text('general.cancel'.tr()),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.white),
                              )
                            : Text(
                                'admin.create'.tr(),
                                style: const TextStyle(color: AppColors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20.sp),
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
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<UserRole>(
              value: role,
              groupValue: _selectedRole,
              onChanged: (v) => setState(() => _selectedRole = v!),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  void _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create user in Firebase Auth
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user == null) throw Exception('Failed to create user');

      // 2. Create user document in Firestore
      final userData = UserModel(
        uid: credential.user!.uid,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        isActive: true,
        createdBy: widget.creatorUid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData.toMap());

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin.create_success'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'errors.email_already_exists'.tr();
          break;
        case 'weak-password':
          message = 'errors.weak_password'.tr();
          break;
        case 'invalid-email':
          message = 'validation.invalid_email'.tr();
          break;
        default:
          message = 'admin.create_error'.tr();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
