import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/view/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const String _onboardingKey = 'has_seen_onboarding';

  final List<OnboardingData> _pages = [
    OnboardingData(
      titleKey: 'onboarding.page1_title',
      descriptionKey: 'onboarding.page1_description',
      image: AppAssets.elderMan,
      showLogo: true,
    ),
    OnboardingData(
      titleKey: 'onboarding.page2_title',
      descriptionKey: 'onboarding.page2_description',
      image: AppAssets.connectIcon,
      showLogo: false,
    ),
    OnboardingData(
      titleKey: 'onboarding.page3_title',
      descriptionKey: 'onboarding.page3_description',
      image: null,
      showLogo: true,
      showAppName: true,
    ),
    OnboardingData(
      titleKey: 'onboarding.page4_title',
      descriptionKey: 'onboarding.page4_description',
      image: AppAssets.healthIcon,
      showLogo: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);

    if (!mounted) return;

    // Navigate to Login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight - 200,
                      ),
                      child: IntrinsicHeight(
                        child: _buildPageContent(_pages[index]),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.lightGrey,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Button
                  CustomButton(
                    text: isLastPage
                        ? 'general.get_started'.tr()
                        : 'general.continue'.tr(),
                    onPressed: _onNextPressed,
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20.h),

          // Logo
          if (data.showLogo) ...[
            Image.asset(
              AppAssets.logo,
              height: 80.h,
            ),
            SizedBox(height: 12.h),
          ],

          // App Name
          if (data.showAppName) ...[
            Text(
              'Sanadi',
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 40.h),
          ],

          // Image
          if (data.image != null) ...[
            Image.asset(
              data.image!,
              height: 180.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 40.h),
          ],

          // Title
          Text(
            data.titleKey.tr(),
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12.h),

          // Description
          Text(
            data.descriptionKey.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String titleKey;
  final String descriptionKey;
  final String? image;
  final bool showLogo;
  final bool showAppName;

  OnboardingData({
    required this.titleKey,
    required this.descriptionKey,
    this.image,
    this.showLogo = false,
    this.showAppName = false,
  });
}
