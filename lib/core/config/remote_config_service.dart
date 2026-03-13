import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// خدمة Firebase Remote Config لإدارة بيانات Super Admin
class RemoteConfigService {
  static RemoteConfigService? _instance;
  static RemoteConfigService get instance => _instance ??= RemoteConfigService._();
  RemoteConfigService._();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  /// تهيئة Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode 
            ? const Duration(seconds: 10)
            : const Duration(hours: 1),
        ),
      );

      // القيم الافتراضية
      await _remoteConfig!.setDefaults({
        'super_admin_email': '',
        'super_admin_password': '',
      });

      // جلب القيم من الخادم
      await _remoteConfig!.fetchAndActivate();
      
      _isInitialized = true;
      print('✅ Remote Config initialized');
    } catch (e) {
      print('⚠️ Remote Config failed: $e');
      _isInitialized = false;
    }
  }

  /// الحصول على إيميل Super Admin
  String get superAdminEmail {
    if (!_isInitialized || _remoteConfig == null) return '';
    return _remoteConfig!.getString('super_admin_email');
  }

  /// الحصول على كلمة مرور Super Admin
  String get superAdminPassword {
    if (!_isInitialized || _remoteConfig == null) return '';
    return _remoteConfig!.getString('super_admin_password');
  }

  /// التحقق من كون الإيميل Super Admin
  bool isSuperAdminEmail(String email) {
    final adminEmail = superAdminEmail;
    if (adminEmail.isEmpty) return false;
    return email.trim().toLowerCase() == adminEmail.trim().toLowerCase();
  }
}