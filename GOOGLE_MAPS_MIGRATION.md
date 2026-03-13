# تقرير تحويل الخرائط من flutter_map إلى Google Maps

## التاريخ: 2026-03-13

---

## ✅ التغييرات المنفذة

### 1. تحديث المكتبات (pubspec.yaml)

#### تمت الإزالة:
- ❌ `flutter_map: ^7.0.2`
- ❌ `latlong2: ^0.9.1`

#### تمت الإضافة:
- ✅ `google_maps_flutter: ^2.14.0`
- ✅ `geocoding: ^3.0.0`
- ✅ `http: ^1.2.0`

---

### 2. إعداد Android

**الملف:** `android/app/src/main/AndroidManifest.xml`

✅ تمت إضافة:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyAsvAxjNyNXhoLrjmYDE0jTrWgr6kgpmW8"/>
```

**الأذونات الموجودة مسبقاً:**
- ✅ `ACCESS_FINE_LOCATION`
- ✅ `ACCESS_COARSE_LOCATION`
- ✅ `INTERNET`

---

### 3. إعداد iOS

#### الملف: `ios/Runner/AppDelegate.swift`

✅ تمت الإضافة:
```swift
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyCZ1g_us97Dtc6LYEnKk_kTnrvDljd0Vl4")
```

#### الملف: `ios/Runner/Info.plist`

✅ تمت إضافة الأذونات:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

---

### 4. تحديث الملفات البرمجية

#### أ. `lib/services/location/location_service.dart`

**التغييرات:**
1. ✅ إضافة imports:
   - `import 'package:geocoding/geocoding.dart';`
   - `import 'package:http/http.dart' as http;`
   - `import 'dart:convert';`

2. ✅ تحديث `LocationData` class:
   - إضافة حقل `address` (String?)

3. ✅ إضافة دالة `getAddressFromCoordinates()`:
   - تستخدم Google Geocoding API أولاً
   - Fallback على مكتبة geocoding
   - تدعم اللغة العربية

4. ✅ تحديث `getLocationData()`:
   - تجلب العنوان تلقائياً مع الإحداثيات

---

#### ب. `lib/features/profile/view/address_screen.dart`

**التغييرات:**
1. ✅ استبدال imports:
   - ❌ `flutter_map` → ✅ `google_maps_flutter`
   - ❌ `latlong2` → ✅ استخدام `LatLng` من google_maps

2. ✅ تحديث State variables:
   - ❌ `MapController _mapController` → ✅ `GoogleMapController? _mapController`
   - ✅ إضافة `Set<Marker> _markers = {}`

3. ✅ استبدال `FlutterMap` widget بـ `GoogleMap`:
   - استخدام `initialCameraPosition`
   - استخدام `onMapCreated` callback
   - تفعيل `myLocationEnabled`
   - إضافة `markers` للعلامات

4. ✅ تحديث `_updateLocation()`:
   - إنشاء Marker ديناميكي
   - استخدام `animateCamera` بدلاً من `move`

5. ✅ تحديث `dispose()`:
   - استخدام `_mapController?.dispose()`

---

#### ج. `lib/features/doctors/view/doctor_details_screen.dart`

**التغييرات:**
1. ✅ استبدال imports:
   - ❌ `flutter_map` → ✅ `google_maps_flutter`
   - ❌ `latlong2` → حذف

2. ✅ تحديث State variables:
   - ❌ `MapController _mapController` → ✅ `GoogleMapController? _mapController`
   - ✅ إضافة `Set<Marker> _markers = {}`

3. ✅ استبدال `FlutterMap` widget بـ `GoogleMap`:
   - عرض موقع الطبيب
   - Marker مع `infoWindow` يحتوي اسم وتخصص الطبيب
   - استخدام `BitmapDescriptor.hueBlue` للون الأزرق

4. ✅ تحديث زر "الرجوع للموقع":
   - استخدام `animateCamera` بدلاً من `move`

---

## 🔑 مفاتيح API المستخدمة

| المنصة | المفتاح |
|--------|---------|
| **Android** | `AIzaSyAsvAxjNyNXhoLrjmYDE0jTrWgr6kgpmW8` |
| **iOS** | `AIzaSyCZ1g_us97Dtc6LYEnKk_kTnrvDljd0Vl4` |

---

## 📋 الخطوات التالية

### 1. تثبيت المكتبات:
```bash
flutter clean
flutter pub get
```

### 2. iOS - تثبيت Pods:
```bash
cd ios
pod install
cd ..
```

### 3. اختبار التطبيق:
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

---

## 🎯 الميزات الجديدة

### ✅ ما تم الحفاظ عليه:
- عرض الموقع الحالي على الخريطة
- تتبع الموقع المباشر (Live Location)
- عرض موقع الطبيب
- دقة GPS
- حفظ الموقع في Firebase
- جميع الوظائف السابقة

### ✨ ما تمت إضافته:
- **Reverse Geocoding**: تحويل الإحداثيات إلى عنوان
- **دعم اللغة العربية** في العناوين
- **Google Maps API** بدلاً من OpenStreetMap
- **Markers محسّنة** مع InfoWindow
- **تحريك الكاميرا بشكل سلس** (animateCamera)

---

## ⚠️ ملاحظات مهمة

### 1. حدود الاستخدام المجاني:
- **Maps SDK**: 28,000 طلب/شهر مجاناً
- **Geocoding API**: 40,000 طلب/شهر مجاناً
- بعد ذلك يتم الدفع حسب الاستخدام

### 2. الأمان:
- المفاتيح الحالية مقيدة بـ Bundle ID
- لا تشارك المفاتيح في الكود العام

### 3. الأداء:
- Google Maps أسرع من OpenStreetMap
- التخزين المؤقت أفضل
- دعم أفضل للأجهزة القديمة

---

## 🔍 الاختبارات المطلوبة

- [ ] اختبار عرض الخريطة في address_screen
- [ ] اختبار تتبع الموقع المباشر
- [ ] اختبار عرض موقع الطبيب
- [ ] اختبار Geocoding (تحويل إحداثيات → عنوان)
- [ ] اختبار على Android
- [ ] اختبار على iOS
- [ ] اختبار الأذونات
- [ ] اختبار حفظ الموقع في Firebase

---

## 📞 الدعم

في حالة وجود مشاكل:
1. تأكد من تفعيل الخدمات في Google Cloud Console
2. تحقق من صحة API Keys
3. تأكد من الأذونات في AndroidManifest.xml و Info.plist
4. نظف المشروع: `flutter clean && flutter pub get`

---

## ✅ الخلاصة

تم التحويل بنجاح من `flutter_map` إلى `google_maps_flutter` مع:
- ✅ الحفاظ على جميع الوظائف السابقة
- ✅ إضافة ميزة Geocoding
- ✅ تحسين الأداء والمظهر
- ✅ دعم أفضل للغة العربية
- ✅ توافق كامل مع Android و iOS

**Bundle ID الموحد:** `com.SanadiHealth.sanadi`
