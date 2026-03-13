import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/permission_info.dart';
import '../view/permission_request_screen.dart';
import '../view/background_location_permission_screen.dart';

class PermissionHelper {
  /// طلب إذن الموقع
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;
    
    if (status.isGranted) return true;
    
    final permissionInfo = PermissionInfo(
      title: 'الوصول إلى موقعك',
      description: 'نحتاج معرفة موقعك لإرسال موقعك لجهات الاتصال الطارئة وتحديد موقعك على الخريطة',
      icon: 'location',
      benefits: [
        'إرسال موقعك الفوري في حالات الطوارئ',
        'تحديد موقعك على الخريطة',
        'العثور على الأطباء والصيدليات القريبة منك',
      ],
      isRequired: true,
    );
    
    bool granted = false;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PermissionRequestScreen(
          permissionInfo: permissionInfo,
          permission: Permission.location,
          onGranted: () => granted = true,
        ),
      ),
    );
    
    return granted;
  }

  /// طلب إذن الموقع في الخلفية
  static Future<bool> requestBackgroundLocationPermission(
    BuildContext context,
  ) async {
    // التأكد من أن إذن الموقع العادي ممنوح أولاً
    final locationGranted = await requestLocationPermission(context);
    if (!locationGranted) return false;
    
    final status = await Permission.locationAlways.status;
    if (status.isGranted) return true;
    
    bool granted = false;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackgroundLocationPermissionScreen(
          onGranted: () => granted = true,
        ),
      ),
    );
    
    return granted;
  }

  /// طلب إذن الكاميرا
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) return true;
    
    final permissionInfo = PermissionInfo(
      title: 'الوصول إلى الكاميرا',
      description: 'نحتاج الكاميرا لقياس معدل ضربات القلب والتقاط صورة الملف الشخصي',
      icon: 'camera',
      benefits: [
        'قياس معدل ضربات القلب باستخدام الكاميرا والفلاش',
        'التقاط صورة الملف الشخصي',
        'مسح الباركود للأدوية (قريباً)',
      ],
      isRequired: false,
    );
    
    bool granted = false;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PermissionRequestScreen(
          permissionInfo: permissionInfo,
          permission: Permission.camera,
          onGranted: () => granted = true,
        ),
      ),
    );
    
    return granted;
  }

  /// طلب إذن الإشعارات
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) return true;
    
    final permissionInfo = PermissionInfo(
      title: 'إرسال الإشعارات',
      description: 'نحتاج إرسال إشعارات لتذكيرك بمواعيد الأدوية والمواعيد الطبية',
      icon: 'notification',
      benefits: [
        'تذكيرك بمواعيد تناول الأدوية',
        'تنبيهك بالمواعيد الطبية القادمة',
        'إشعارات مهمة عن حالتك الصحية',
      ],
      isRequired: true,
    );
    
    bool granted = false;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PermissionRequestScreen(
          permissionInfo: permissionInfo,
          permission: Permission.notification,
          onGranted: () => granted = true,
        ),
      ),
    );
    
    return granted;
  }

  /// التحقق من حالة جميع الأذونات المهمة
  /// ملاحظة: لا نطلب صلاحية الصور لأن image_picker يستخدم Photo Picker API
  /// على Android 13+ بدون الحاجة لصلاحيات
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'locationAlways': await Permission.locationAlways.isGranted,
      'camera': await Permission.camera.isGranted,
      'notification': await Permission.notification.isGranted,
    };
  }

  /// فتح إعدادات التطبيق
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
