import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/social_button.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../../../core/utils/validators.dart';
import '../viewmodel/auth_cubit.dart';
import '../viewmodel/auth_state.dart';
// import '../model/user_model.dart'; // تم الحذف - لم يعد مطلوباً
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // ✅ إزالة متغير الدور - لا يجب أن يختار المستخدم دوره
  // UserRole _selectedRole = UserRole.user; // تم الحذف

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('validation.accept_terms'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final formattedPhone =
          Validators.formatPhoneToE164(_phoneController.text.trim());

      context.read<AuthCubit>().register(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: formattedPhone,
            password: _passwordController.text,
          );
    }
  }

  void _signUpWithGoogle() {
    context.read<AuthCubit>().loginWithGoogle();
  }

  void _signUpWithFacebook() {
    context.read<AuthCubit>().loginWithFacebook();
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('success.account_created'.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  Widget _buildDesktopLayout(BuildContext context, AuthState state) {
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
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(48, 80, 48, 48),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: _buildForm(context, state, isDesktop: true),
                        ),
                      ),
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

  Widget _buildMobileLayout(BuildContext context, AuthState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                child: const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: LanguageButton(),
                ),
              ),
              _buildForm(context, state, isDesktop: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthState state,
      {required bool isDesktop}) {
    // final lang = context.locale.languageCode; // تم الحذف - لم يعد مطلوباً

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'auth.sign_up'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 32 : 32.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isDesktop ? 8 : 8.h),

          Text(
            'auth.sign_up_subtitle'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 16 : 16.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isDesktop ? 32 : 32.h),

          // Full Name
          _buildTextField(
            controller: _nameController,
            hintText: 'auth.full_name'.tr(),
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
            validator: Validators.validateName,
            isDesktop: isDesktop,
          ),

          SizedBox(height: isDesktop ? 16 : 16.h),

          // Email
          _buildTextField(
            controller: _emailController,
            hintText: 'auth.email'.tr(),
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            isDesktop: isDesktop,
          ),

          SizedBox(height: isDesktop ? 16 : 16.h),

          // Phone
          _buildTextField(
            controller: _phoneController,
            hintText: '10xxxxxxxx',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            isDesktop: isDesktop,
            prefixText: '+20 ',
          ),

          SizedBox(height: isDesktop ? 16 : 16.h),

          // ✅ Role Selector - تم الحذف لأنه غير منطقي
          // _buildRoleSelector(lang, isDesktop),

          // SizedBox(height: isDesktop ? 16 : 16.h),

          // Password
          _buildTextField(
            controller: _passwordController,
            hintText: 'auth.password'.tr(),
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

          // Confirm Password
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'auth.confirm_password'.tr(),
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

          SizedBox(height: isDesktop ? 16 : 16.h),

          // Terms Checkbox
          _buildCheckbox(isDesktop),

          SizedBox(height: isDesktop ? 24 : 24.h),

          // Sign Up Button
          _buildButton(
            text: 'auth.sign_up'.tr(),
            onPressed: _signUp,
            isLoading: state is AuthLoading,
            isDesktop: isDesktop,
          ),

          SizedBox(height: isDesktop ? 16 : 16.h),

          // Login Link
          _buildOutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            isDesktop: isDesktop,
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: isDesktop ? 14 : 14.sp),
                children: [
                  TextSpan(
                    text: 'auth.have_account'.tr(),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'auth.login'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isDesktop ? 24 : 24.h),

          _buildDivider(isDesktop),

          SizedBox(height: isDesktop ? 24 : 24.h),

          _buildSocialButtons(isDesktop),

          SizedBox(height: isDesktop ? 24 : 24.h),
        ],
      ),
    );
  }

  // ✅ Role Selector Widget - تم الحذف لأنه غير منطقي
  // Widget _buildRoleSelector(String lang, bool isDesktop) { ... }

  // ✅ أيقونة حسب الدور - تم الحذف
  // IconData _getRoleIcon(UserRole role) { ... }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    required bool isDesktop,
    String? prefixText,
  }) {
    if (isDesktop) {
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixText: prefixText,
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
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildCheckbox(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) =>
                setState(() => _agreeToTerms = value ?? false),
            activeColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isDesktop ? 13 : 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'auth.terms_text'.tr()),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'auth.terms_highlight'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildOutlinedButton({
    required VoidCallback onPressed,
    required Widget child,
    required bool isDesktop,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isDesktop ? 52 : 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 12 : 16)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildDivider(bool isDesktop) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.lightGrey)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 16.w),
          child: Text(
            'general.or'.tr(),
            style: TextStyle(
                fontSize: isDesktop ? 14 : 14.sp,
                color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.lightGrey)),
      ],
    );
  }

  Widget _buildSocialButtons(bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _signUpWithFacebook,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.lightGrey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppAssets.facebookIcon, width: 24, height: 24),
                    const SizedBox(width: 8),
                    Text('auth.facebook'.tr(),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _signUpWithGoogle,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.lightGrey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppAssets.googleIcon, width: 24, height: 24),
                    const SizedBox(width: 8),
                    Text('auth.google'.tr(),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SocialButton(
            text: 'auth.facebook'.tr(),
            iconPath: AppAssets.facebookIcon,
            onPressed: _signUpWithFacebook,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: SocialButton(
            text: 'auth.google'.tr(),
            iconPath: AppAssets.googleIcon,
            onPressed: _signUpWithGoogle,
          ),
        ),
      ],
    );
  }
}
