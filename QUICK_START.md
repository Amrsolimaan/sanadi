# 🚀 دليل البدء السريع - تحديث تطبيق سندي

## 📋 ما تم إنشاؤه

### 1️⃣ سياسة الخصوصية (HTML)
📁 **المجلد:** `privacy-policy/`
- `index.html` - صفحة سياسة الخصوصية جاهزة للرفع

### 2️⃣ نظام طلب الأذونات (4 ملفات جديدة)
📁 **المجلد:** `lib/features/permissions/`
```
permissions/
├── model/permission_info.dart
├── view/
│   ├── permission_request_screen.dart
│   └── background_location_permission_screen.dart
└── utils/permission_helper.dart
```

**ملاحظة:** نظام الأذونات يدعم:
- ✅ إذن الموقع (Location)
- ✅ إذن الموقع في الخلفية (Background Location)
- ✅ إذن الإشعارات (Notifications)
- ✅ إذن الصور (Photos)
- ⚠️ إذن الكاميرا (موجود في الكود لكن غير مستخدم حالياً)

### 3️⃣ تحديث AndroidManifest.xml
✅ تم تحديث أذونات التخزين تلقائياً

### 4️⃣ ملفات التوثيق
- `UPDATE_SUMMARY.md` - دليل شامل للتحديثات
- `GOOGLE_PLAY_CONSOLE_GUIDE.md` - دليل ملء نماذج Google Play
- `COMPLIANCE_README.md` - دليل التوافق الكامل
- `QUICK_START.md` - هذا الملف

---

## ⚡ خطوات سريعة (30 دقيقة)

### الخطوة 1: تعديل سياسة الخصوصية (5 دقائق)
1. افتح `privacy-policy/index.html`
2. ابحث عن `[أضف بريدك الإلكتروني]` واستبدله ببريدك
3. ابحث عن `[أضف موقعك]` واستبدله بموقعك (أو احذفه)
4. ابحث عن `[بلدك]` واستبدله باسم بلدك
5. احفظ الملف

### الخطوة 2: رفع على GitHub (10 دقائق)
```bash
# في terminal
cd privacy-policy
git init
git add .
git commit -m "Add privacy policy"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/sanadi-privacy.git
git push -u origin main
```

ثم:
1. اذهب إلى GitHub > Repository Settings > Pages
2. اختر Branch: main, Folder: / (root)
3. احفظ
4. انتظر دقيقة
5. الرابط: `https://YOUR_USERNAME.github.io/sanadi-privacy/privacy-policy/`

### الخطوة 3: تحديث Google Play Console (10 دقائق)
1. اذهب إلى Google Play Console
2. **App content** > **Privacy policy**
3. أضف الرابط من الخطوة 2
4. احفظ

### الخطوة 4: إضافة الكود في التطبيق (5 دقائق)

**في أي ملف تطلب فيه أذونات، استبدل:**

```dart
// ❌ القديم
await Permission.location.request();

// ✅ الجديد
import 'package:sanadi/features/permissions/utils/permission_helper.dart';

await PermissionHelper.requestLocationPermission(context);
```

**أمثلة الاستخدام:**

```dart
// إذن الموقع
final granted = await PermissionHelper.requestLocationPermission(context);

// إذن الموقع في الخلفية (للطوارئ فقط)
final granted = await PermissionHelper.requestBackgroundLocationPermission(context);

// إذن الإشعارات (للتذكير بالأدوية)
final granted = await PermissionHelper.requestNotificationPermission(context);

// إذن الصور (لصورة الملف الشخصي)
final granted = await PermissionHelper.requestPhotosPermission(context);
```

---

## 🎯 الأماكن التي تحتاج تحديث

### 1. ميزة الطوارئ (Emergency)
**الملف:** `lib/features/emergency/...`

```dart
// عند تفعيل ميزة الطوارئ لأول مرة
final locationGranted = await PermissionHelper.requestLocationPermission(context);
if (locationGranted) {
  final backgroundGranted = await PermissionHelper.requestBackgroundLocationPermission(context);
  if (backgroundGranted) {
    // فعّل ميزة الطوارئ
  }
}
```

### 2. تذكير الأدوية (Medications)
**الملف:** `lib/features/medications/...`

```dart
// عند إضافة أول دواء
final granted = await PermissionHelper.requestNotificationPermission(context);
if (granted) {
  // احفظ الدواء وفعّل التذكير
}
```

### 3. الصورة الشخصية (Profile Picture)
**الملف:** `lib/features/profile/...`

```dart
// عند اختيار صورة من المعرض
final granted = await PermissionHelper.requestPhotosPermission(context);
if (granted) {
  // افتح معرض الصور
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
}
```

---

## 📝 تحديثات Google Play Console

### إذا لم تكن قد ملأت Data Safety Section:

اذهب إلى **App content** > **Data safety** وأضف:

**البيانات المجمعة:**
- ✅ Location (Precise & Approximate)
- ✅ Health data (Medication records, Medical appointments)
- ✅ Photos
- ✅ Personal info (Name, Email, Phone)
- ✅ App activity (Analytics)
- ✅ Device IDs

**ملاحظة:** لا تضف Heart Rate لأنك لم تستخدم هذه الميزة

**لكل نوع:**
- هل يتم جمعها؟ نعم
- هل مشفرة؟ نعم
- هل يمكن حذفها؟ نعم
- السبب؟ App functionality

### إذا لم تكن قد ملأت Background Location Declaration:

اذهب إلى **App content** > **Sensitive permissions** > **Background location**

**الإجابة:**
```
نستخدم الموقع في الخلفية لميزة الطوارئ. عند الضغط على زر الطوارئ،
يُرسل موقع المستخدم فوراً لجهات الاتصال الطارئة (الأقارب).
هذه ميزة أساسية لسلامة كبار السن.
```

---

## 🧪 الاختبار

### اختبار سريع (5 دقائق):
```bash
flutter run --release
```

**اختبر:**
1. اطلب إذن الموقع → يجب أن تظهر شاشة توضيحية
2. اطلب إذن الكاميرا → يجب أن تظهر شاشة توضيحية
3. ارفض الإذن → التطبيق لا يتعطل
4. اقبل الإذن → الميزة تعمل

---

## 📦 البناء والرفع

```bash
# نظف المشروع
flutter clean

# احصل على الحزم
flutter pub get

# ابنِ التطبيق
flutter build appbundle --release

# الملف في:
# build/app/outputs/bundle/release/app-release.aab
```

ارفع على Google Play Console:
1. **Production** أو **Testing**
2. ارفع الـ AAB
3. أضف ملاحظات الإصدار
4. اضغط **Submit**

---

## ✅ قائمة التحقق السريعة

قبل الرفع:
- [ ] عدّلت معلومات الاتصال في index.html
- [ ] رفعت سياسة الخصوصية على GitHub
- [ ] الرابط يعمل
- [ ] حدّثت رابط Privacy Policy في Console
- [ ] أضفت استخدام PermissionHelper في الكود
- [ ] اختبرت الأذونات
- [ ] بنيت الـ AAB

---

## 🆘 مشاكل شائعة

### المشكلة: الرابط لا يعمل
**الحل:** تأكد من تفعيل GitHub Pages وانتظر 5 دقائق

### المشكلة: الشاشات التوضيحية لا تظهر
**الحل:** تأكد من استيراد `permission_helper.dart` واستخدام الدوال الصحيحة

### المشكلة: Google Play يرفض التطبيق
**الحل:** تأكد من ملء Background Location Declaration إذا كنت تستخدم الموقع في الخلفية

---

## 📞 تحتاج مساعدة؟

راجع الملفات التفصيلية:
- `UPDATE_SUMMARY.md` - دليل شامل
- `GOOGLE_PLAY_CONSOLE_GUIDE.md` - دليل Console
- `COMPLIANCE_README.md` - دليل التوافق الكامل

---

**الوقت الإجمالي المتوقع:** 30-60 دقيقة

**حظاً موفقاً! 🚀**
