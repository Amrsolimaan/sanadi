import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanadi/features/home/view/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../auth/view/login_screen.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import '../../profile/viewmodel/profile_cubit.dart';
import '../../medications/viewmodel/medication_cubit.dart';
import '../../../services/firestore/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _onboardingKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // انتظر عرض الـ splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // ✅ انتظر تحميل حالة المصادقة من Firebase
      await FirebaseAuth.instance.authStateChanges().first;

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // ✅ المستخدم مسجل دخول - حمّل بياناته من Firestore
        await _loadUserAndNavigate(currentUser);
      } else {
        // ❌ المستخدم غير مسجل دخول
        await _navigateToLoginOrOnboarding();
      }
    } catch (e) {
      // في حالة حدوث خطأ، انتقل للـ login/onboarding
      debugPrint('Error in splash: $e');
      await _navigateToLoginOrOnboarding();
    }
  }

  /// تحميل بيانات المستخدم والانتقال للشاشة الرئيسية
  Future<void> _loadUserAndNavigate(User currentUser) async {
    if (!mounted) return;

    try {
      final userService = UserService();
      final userData = await userService.getUser(currentUser.uid);

      if (!mounted) return;

      if (userData != null) {
        // ✅ البيانات موجودة - حمّلها في AuthCubit
        context.read<AuthCubit>().emit(AuthSuccess(user: userData));

        // ✅ تحميل ProfileCubit لضمان ظهور زر Admin فوراً
        context.read<ProfileCubit>().emit(ProfileLoaded(userData));

        // ✅ تحميل الأدوية فوراً عند الدخول
        context.read<MedicationCubit>().loadMedications();

        // انتقل للشاشة الرئيسية
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // ❌ البيانات غير موجودة في Firestore - سجل خروج
        debugPrint('User data not found in Firestore');
        await FirebaseAuth.instance.signOut();
        await _navigateToLoginOrOnboarding();
      }
    } catch (e) {
      // ❌ خطأ في تحميل البيانات - سجل خروج
      debugPrint('Error loading user data: $e');
      await FirebaseAuth.instance.signOut();
      await _navigateToLoginOrOnboarding();
    }
  }

  /// الانتقال لشاشة Login أو Onboarding
  Future<void> _navigateToLoginOrOnboarding() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

    if (!mounted) return;

    if (hasSeenOnboarding) {
      // المستخدم شاهد الـ onboarding من قبل → اذهب للـ Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // أول مرة → اعرض Onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
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
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              color: AppColors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
