# دليل Firebase Remote Config - إدارة بيانات Super Admin

## الخطوات:

### 1. إضافة القيم في Firebase Console
1. اذهب إلى Firebase Console → Remote Config
2. أضف المفاتيح التالية:
   - `super_admin_email`: إيميل Super Admin
   - `super_admin_password`: كلمة مرور Super Admin

### 2. تهيئة التطبيق
في `main.dart` أضف:
```dart
import 'package:sanadi/core/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  runApp(MyApp());
}
```

### 3. الاستخدام
الآن بيانات Super Admin ستأتي من Remote Config بدلاً من الكود المكتوب بشكل ثابت.

## الملفات المضافة:
- `lib/core/config/remote_config_service.dart` - خدمة Remote Config
- `lib/core/app_initializer.dart` - تهيئة التطبيق

## ملاحظة أمنية:
في الإنتاج، لا تضع كلمة المرور في Remote Config. استخدم إيميل فقط وأنشئ الحساب يدوياً في Firebase Auth.