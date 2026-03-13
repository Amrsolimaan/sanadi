import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

class AuthResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final String title;
  final String subtitle;

  const AuthResponsiveLayout({
    super.key,
    required this.mobileLayout,
    required this.title,
    required this.subtitle,
  });

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLargeScreen(context)) {
      return _buildDesktopLayout(context);
    }
    return mobileLayout;
  }

  Widget _buildDesktopLayout(BuildContext context) {
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
                  // Logo
                  Image.asset(
                    AppAssets.logo,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  const Text(
                    'Sanadi',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tagline
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your Companion for a Happy & Fulfilling Life',
                      style: TextStyle(
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: mobileLayout is Scaffold
                        ? _extractFormFromScaffold(mobileLayout as Scaffold)
                        : mobileLayout,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _extractFormFromScaffold(Scaffold scaffold) {
    if (scaffold.body is SafeArea) {
      final safeArea = scaffold.body as SafeArea;
      return safeArea.child;
    }
    return scaffold.body ?? const SizedBox();
  }
}
