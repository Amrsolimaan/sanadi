# دليل البدء السريع - Google Maps

## 🚀 خطوات التشغيل

### 1. تنظيف المشروع
```bash
flutter clean
flutter pub get
```

### 2. تثبيت iOS Pods
```bash
cd ios
pod install
cd ..
```

### 3. تشغيل التطبيق

#### Android:
```bash
flutter run
```

#### iOS:
```bash
flutter run -d ios
```

---

## 🔑 المفاتيح المستخدمة

### Android API Key:
```
AIzaSyAsvAxjNyNXhoLrjmYDE0jTrWgr6kgpmW8
```
**الموقع:** `android/app/src/main/AndroidManifest.xml`

### iOS API Key:
```
AIzaSyCZ1g_us97Dtc6LYEnKk_kTnrvDljd0Vl4
```
**الموقع:** `ios/Runner/AppDelegate.swift`

---

## 📱 الشاشات المحدثة

### 1. شاشة العنوان (Address Screen)
- **المسار:** `lib/features/profile/view/address_screen.dart`
- **الوظائف:**
  - عرض الموقع الحالي
  - تتبع مباشر (Live Location)
  - حفظ في Firebase
  - عرض دقة GPS

### 2. شاشة تفاصيل الطبيب (Doctor Details)
- **المسار:** `lib/features/doctors/view/doctor_details_screen.dart`
- **الوظائف:**
  - عرض موقع الطبيب
  - Marker مع معلومات
  - زر الرجوع للموقع

---

## 🆕 الميزات الجديدة

### Reverse Geocoding
تحويل الإحداثيات إلى عنوان بالعربي:

```dart
final address = await locationService.getAddressFromCoordinates(lat, lng);
```

**مثال النتيجة:**
```
شارع التحرير، وسط البلد، القاهرة، محافظة القاهرة، مصر
```

---

## ⚠️ استكشاف الأخطاء

### المشكلة: الخريطة لا تظهر على Android

**الحل:**
1. تأكد من وجود API Key في `AndroidManifest.xml`
2. تأكد من تفعيل **Maps SDK for Android** في Google Cloud Console
3. نظف المشروع: `flutter clean && flutter pub get`

### المشكلة: الخريطة لا تظهر على iOS

**الحل:**
1. تأكد من تشغيل `pod install` في مجلد `ios`
2. تأكد من وجود API Key في `AppDelegate.swift`
3. تأكد من تفعيل **Maps SDK for iOS** في Google Cloud Console
4. احذف مجلد `ios/Pods` وشغل `pod install` مرة أخرى

### المشكلة: خطأ في الأذونات

**الحل:**
- **Android:** تأكد من الأذونات في `AndroidManifest.xml`
- **iOS:** تأكد من الأذونات في `Info.plist`

### المشكلة: Geocoding لا يعمل

**الحل:**
1. تأكد من تفعيل **Geocoding API** في Google Cloud Console
2. تأكد من وجود اتصال بالإنترنت
3. تحقق من صحة API Key

---

## 📊 حدود الاستخدام المجاني

| الخدمة | الحد المجاني |
|--------|--------------|
| Maps SDK for Android | 28,000 طلب/شهر |
| Maps SDK for iOS | 28,000 طلب/شهر |
| Geocoding API | 40,000 طلب/شهر |

---

## 🔗 روابط مفيدة

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Maps Platform](https://developers.google.com/maps)
- [google_maps_flutter Package](https://pub.dev/packages/google_maps_flutter)
- [geocoding Package](https://pub.dev/packages/geocoding)

---

## ✅ قائمة التحقق

قبل النشر، تأكد من:

- [ ] اختبار الخرائط على Android
- [ ] اختبار الخرائط على iOS
- [ ] اختبار الأذونات
- [ ] اختبار Geocoding
- [ ] اختبار حفظ الموقع
- [ ] اختبار في بيئة الإنتاج
- [ ] مراجعة حدود الاستخدام
- [ ] تأمين API Keys

---

## 🎉 تم بنجاح!

التطبيق الآن يستخدم Google Maps بدلاً من flutter_map مع الحفاظ على جميع الوظائف وإضافة ميزات جديدة!
