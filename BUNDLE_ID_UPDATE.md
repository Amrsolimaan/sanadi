# تحديث Bundle ID للمشروع

## التاريخ: 2026-03-13

## التغييرات المنفذة ✅

تم توحيد Bundle ID عبر جميع المنصات ليكون:

```
com.SanadiHealth.sanadi
```

### قبل التحديث:
- **iOS:** `com.example.sanadi`
- **Android:** `com.SanadiHealth.sanadi`
- **macOS:** `com.example.sanadi`

### بعد التحديث:
- **iOS:** `com.SanadiHealth.sanadi` ✅
- **Android:** `com.SanadiHealth.sanadi` ✅
- **macOS:** `com.SanadiHealth.sanadi` ✅

---

## الملفات المحدثة:

### iOS:
- `ios/Runner.xcodeproj/project.pbxproj`
  - تم تحديث 6 مواضع (Debug, Release, Profile لكل من Runner و RunnerTests)

### macOS:
- `macos/Runner.xcodeproj/project.pbxproj`
  - تم تحديث 3 مواضع (Debug, Release, Profile للـ RunnerTests)

### Android:
- لم يتطلب تحديث (كان صحيحاً بالفعل)

---

## الخطوات التالية:

### 1. إنشاء مفاتيح API:
استخدم Bundle ID الجديد عند إنشاء مفاتيح:
```
com.SanadiHealth.sanadi
```

### 2. تحديث Firebase (إذا لزم الأمر):
- تحديث iOS Bundle ID في Firebase Console
- تنزيل `GoogleService-Info.plist` الجديد
- استبدال الملف القديم في `ios/Runner/`

### 3. تحديث Apple Developer:
- تسجيل Bundle ID الجديد في Apple Developer Portal
- إنشاء Provisioning Profiles جديدة

### 4. تنظيف المشروع:
```bash
# تنظيف Flutter
flutter clean

# تنظيف iOS
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# إعادة البناء
flutter pub get
flutter build ios
```

---

## ملاحظات مهمة:

⚠️ **تحذير:** بعد هذا التغيير:
- لن تتمكن من تحديث التطبيق القديم مباشرة (Bundle ID مختلف)
- ستحتاج لإعادة نشر التطبيق كإصدار جديد
- المستخدمون سيحتاجون لتثبيت التطبيق من جديد

✅ **الفوائد:**
- توحيد الهوية عبر جميع المنصات
- احترافية أكثر في التسمية
- سهولة إدارة المفاتيح والشهادات

---

## للاستخدام الفوري:

Bundle ID للاستخدام في إنشاء مفاتيح Google Maps أو أي خدمات أخرى:

```
com.SanadiHealth.sanadi
```
