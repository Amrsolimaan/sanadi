import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../../../core/utils/validators.dart';
import '../viewmodel/auth_cubit.dart';
import '../viewmodel/auth_state.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().resetPassword(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is PasswordResetDone) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('success.password_changed'.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, authState) {
            if (isLarge) {
              return _buildDesktopLayout(context, authState);
            }
            return _buildMobileLayout(context, authState);
          },
        );
      },
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(BuildContext context, AuthState state) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Row(
        children: [
          // Left Side - Branding
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'onboarding.page1_description'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side - Form
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
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildForm(context, state, isDesktop: true),
                      ),
                    ),
                  ),
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
  Widget _buildMobileLayout(BuildContext context, AuthState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildForm(context, state, isDesktop: false),
        ),
      ),
    );
  }

  // Shared Form
  Widget _buildForm(BuildContext context, AuthState state,
      {required bool isDesktop}) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(height: isDesktop ? 0 : 20.h),

          // Lock Icon
          Container(
            width: isDesktop ? 100 : 80.w,
            height: isDesktop ? 100 : 80.h,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.lockIcon,
                width: isDesktop ? 56 : 48.w,
                height: isDesktop ? 56 : 48.h,
              ),
            ),
          ),

          SizedBox(height: isDesktop ? 32 : 24.h),

          // Title
          Text(
            'auth.reset_password'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 28 : 28.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          SizedBox(height: isDesktop ? 12 : 12.h),

          // Subtitle
          Text(
            'auth.reset_password_subtitle'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 14 : 14.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isDesktop ? 40 : 40.h),

          // New Password Field
          _buildTextField(
            controller: _passwordController,
            hintText: 'auth.new_password'.tr(),
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            validator: Validators.validatePassword,
            isDesktop: isDesktop,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          SizedBox(height: isDesktop ? 16 : 16.h),

          // Confirm Password Field
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'auth.confirm_new_password'.tr(),
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            validator: (value) => Validators.validateConfirmPassword(
                value, _passwordController.text),
            isDesktop: isDesktop,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),

          SizedBox(height: isDesktop ? 40 : 40.h),

          // Change Password Button
          _buildButton(
            text: 'auth.change_password'.tr(),
            onPressed: _changePassword,
            isLoading: state is AuthLoading,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    required bool isDesktop,
  }) {
    if (isDesktop) {
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon: Icon(prefixIcon, color: AppColors.textHint, size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.scaffoldBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      );
    }

    return CustomTextField(
      controller: controller,
      hintText: hintText,
      prefixIcon: prefixIcon,
      obscureText: obscureText,
      validator: validator,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
    required bool isDesktop,
  }) {
    if (isDesktop) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2.5),
                )
              : Text(text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return CustomButton(text: text, onPressed: onPressed, isLoading: isLoading);
  }
}
