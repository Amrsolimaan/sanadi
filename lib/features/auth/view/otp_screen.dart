import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/otp_field.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../viewmodel/auth_cubit.dart';
import '../viewmodel/auth_state.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _verifyOtp() {
    if (_otp.length == 6) {
      context.read<AuthCubit>().verifyOtp(otp: _otp);
    }
  }

  void _resendOtp() {
    context.read<AuthCubit>().sendOtp(widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is OtpVerified) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is OtpSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('success.otp_sent'.tr()),
                  backgroundColor: AppColors.success,
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
    return Column(
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
          'auth.otp_title'.tr(),
          style: TextStyle(
            fontSize: isDesktop ? 28 : 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),

        SizedBox(height: isDesktop ? 12 : 12.h),

        // Subtitle
        Text(
          'auth.otp_subtitle'.tr(),
          style: TextStyle(
            fontSize: isDesktop ? 14 : 14.sp,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: isDesktop ? 8 : 8.h),

        // Phone Number
        Text(
          widget.phoneNumber,
          style: TextStyle(
            fontSize: isDesktop ? 16 : 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: isDesktop ? 40 : 40.h),

        // OTP Field
        OtpField(
          length: 6,
          onCompleted: (otp) => setState(() => _otp = otp),
          onChanged: (otp) => setState(() => _otp = otp),
        ),

        SizedBox(height: isDesktop ? 24 : 24.h),

        // Resend Code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'auth.didnt_receive'.tr(),
              style: TextStyle(
                fontSize: isDesktop ? 14 : 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: _resendOtp,
              child: Text(
                'auth.resend_code'.tr(),
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: isDesktop ? 40 : 40.h),

        // Verify Button
        _buildButton(
          text: 'auth.verify'.tr(),
          onPressed: _verifyOtp,
          isLoading: state is AuthLoading,
          isDesktop: isDesktop,
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
}
