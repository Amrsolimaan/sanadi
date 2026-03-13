import 'package:firebase_core/firebase_core.dart';
import 'package:sanadi/core/config/remote_config_service.dart';
import '../firebase_options.dart'; // ✅ إضافة Firebase options

/// تهيئة التطبيق عند البدء
class AppInitializer {
  static bool _isInitialized = false;

  /// تهيئة جميع الخدمات المطلوبة
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized');

      // تهيئة Remote Config
      await RemoteConfigService.instance.initialize();
      print('✅ Remote Config initialized');

      _isInitialized = true;
      print('✅ App initialization completed');
    } catch (e) {
      print('🔴 App initialization failed: $e');
      rethrow;
    }
  }

  /// التحقق من حالة التهيئة
  static bool get isInitialized => _isInitialized;
}