import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/localization/locale_config.dart';
import 'core/localization/language_cubit.dart';
import 'core/themes/app_theme.dart';
import 'core/app_initializer.dart'; // ✅ إضافة تهيئة التطبيق
// Auth
import 'features/auth/viewmodel/auth_cubit.dart';
// Profile
import 'features/profile/viewmodel/profile_cubit.dart';
// Home
import 'features/home/viewmodel/home_cubit.dart';
// Emergency
import 'features/emergency/viewmodel/emergency_contacts_cubit.dart';
// Location
import 'features/location/viewmodel/location_cubit.dart';
// Doctors
import 'features/doctors/viewmodel/doctors_cubit.dart';
import 'features/doctors/viewmodel/doctor_details_cubit.dart';
import 'features/doctors/viewmodel/booking_cubit.dart';
import 'features/doctors/viewmodel/appointments_cubit.dart';
// Medications
import 'features/medications/viewmodel/medication_cubit.dart';
// Health
import 'features/health/viewmodel/health_cubit.dart';
// ========== Grocery ========== ✅ NEW
import 'features/grocery/viewmodel/grocery_cubit.dart';
import 'features/grocery/viewmodel/cart_cubit.dart';
import 'features/grocery/viewmodel/order_cubit.dart';
// ========== Admin ========== ✅ NEW
import 'features/grocery_admin/viewmodel/admin_cubit.dart';
// Splash
import 'features/splash/view/splash_screen.dart';
// Services
import 'services/firestore/alarm_service.dart';
import 'services/firestore/persistent_alarm_service.dart';
import 'services/firestore/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase و Remote Config
  await AppInitializer.initialize();

  // ✅ Initialize Supabase بشكل صحيح (للـ Storage فقط)
  await Supabase.initialize(
    url: 'https://pljrxqzinvdcyxffablj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsanJ4cXppbnZkY3l4ZmZhYmxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU5MTk2NjEsImV4cCI6MjA1MTQ5NTY2MX0.6vqGHH-xkPYEq9g3fxAoH4QE5OMjJMNNqVpZpxLCWzI',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: false, // ✅ معطّل لأننا نستخدم Firebase Auth
    ),
  );

  // Initialize Localization
  await EasyLocalization.ensureInitialized();

  // Initialize Alarm Service for Medications
  await AlarmService.initialize();
  
  // ✅ إعادة جدولة المنبهات عند بدء التطبيق
  await PersistentAlarmService.rescheduleAlarmsOnStartup();

  // Set Preferred Orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: LocaleConfig.supportedLocales,
      path: LocaleConfig.translationsPath,
      fallbackLocale: LocaleConfig.fallbackLocale,
      // ✅ إزالة startLocale لأخذ لغة الجهاز تلقائياً
      // عند عدم تحديد startLocale، سيستخدم EasyLocalization لغة الجهاز الافتراضية
      child: const SanadiApp(),
    ),
  );
}

class SanadiApp extends StatelessWidget {
  const SanadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ========== Core ==========
        BlocProvider(create: (_) => LanguageCubit()),
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(
          create: (_) => ProfileCubit(
            userService: UserService(),
            auth: FirebaseAuth.instance,
          ),
        ),

        // ========== Home ==========
        BlocProvider(create: (_) => HomeCubit()),

        // ========== Emergency ==========
        BlocProvider(create: (_) => EmergencyContactsCubit()),
        BlocProvider(create: (_) => LocationCubit()),

        // ========== Doctors ==========
        BlocProvider(create: (_) => DoctorsCubit()),
        BlocProvider(create: (_) => DoctorDetailsCubit()),
        BlocProvider(create: (_) => BookingCubit()),
        BlocProvider(create: (_) => AppointmentsCubit()),

        // ========== Medications ==========
        BlocProvider(create: (_) => MedicationCubit()),

        // ========== Health ==========
        BlocProvider(create: (_) => HealthCubit()),

        // ========== Grocery ========== ✅ NEW
        BlocProvider(create: (_) => GroceryCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => OrderHistoryCubit()),

        // ========== Admin ========== ✅ NEW
        BlocProvider(create: (_) => AdminCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        ensureScreenSize: true,
        builder: (context, child) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            title: 'Sanadi',
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
