# 📋 ملخص التحديثات المطلوبة - تطبيق سندي

## ✅ ما تم إنشاؤه

### 1. ملف سياسة الخصوصية HTML
📁 **الموقع:** `privacy-policy/index.html`

**ما يجب فعله:**
1. افتح الملف وعدّل المعلومات التالية:
   - `[أضف بريدك الإلكتروني]` → ضع بريدك الفعلي
   - `[أضف موقعك]` → ضع رابط موقعك (إن وجد)
   - `[أضف عنوانك]` → ضع عنوانك (اختياري)
   - `[بلدك]` → ضع اسم بلدك

2. ارفع المجلد `privacy-policy` على GitHub:
   ```bash
   # إذا لم يكن لديك repository
   git init
   git add privacy-policy/
   git commit -m "Add privacy policy"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/sanadi-privacy.git
   git push -u origin main
   
   # فعّل GitHub Pages من Settings > Pages
   # اختر branch: main, folder: / (root)
   ```

3. الرابط سيكون:
   ```
   https://YOUR_USERNAME.github.io/sanadi-privacy/privacy-policy/
   ```

---

### 2. نظام طلب الأذونات (جديد)
هذه ملفات جديدة لتحسين تجربة المستخدم عند طلب الأذونات:

#### 📁 الملفات المُنشأة:
```
lib/features/permissions/
├── model/
│   └── permission_info.dart
├── view/
│   ├── permission_request_screen.dart
│   └── background_location_permission_screen.dart
└── utils/
    └── permission_helper.dart
```

#### 🔧 كيفية الاستخدام:

**مثال 1: طلب إذن الموقع**
```dart
import 'package:sanadi/features/permissions/utils/permission_helper.dart';

// في أي مكان تحتاج فيه إذن الموقع
final granted = await PermissionHelper.requestLocationPermission(context);
if (granted) {
  // المستخدم منح الإذن - تابع العملية
  _startLocationTracking();
} else {
  // المستخدم رفض - أظهر رسالة
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('نحتاج إذن الموقع لهذه الميزة')),
  );
}
```

**مثال 2: طلب إذن الموقع في الخلفية**
```dart
// استخدم هذا فقط عند تفعيل ميزة الطوارئ
final granted = await PermissionHelper.requestBackgroundLocationPermission(context);
```

**مثال 3: طلب إذن الكاميرا**
```dart
// قبل فتح الكاميرا لقياس ضربات القلب
final granted = await PermissionHelper.requestCameraPermission(context);
if (granted) {
  _startHeartRateMeasurement();
}
```

**مثال 4: طلب إذن الإشعارات**
```dart
// عند تفعيل تذكيرات الأدوية لأول مرة
final granted = await PermissionHelper.requestNotificationPermission(context);
```

---

### 3. تحديث AndroidManifest.xml
✅ **تم بالفعل:** تحديث أذونات التخزين لتكون متوافقة مع Android 13+

**ما تم تغييره:**
```xml
<!-- قبل -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- بعد -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>
```

---

## 🔄 ما يجب تحديثه في Google Play Console

### 1. تحديث رابط سياسة الخصوصية
📍 **المكان:** App content > Privacy policy

**الخطوات:**
1. اذهب إلى Google Play Console
2. اختر تطبيقك
3. من القائمة: **App content** > **Privacy policy**
4. أضف الرابط الجديد: `https://YOUR_USERNAME.github.io/sanadi-privacy/privacy-policy/`
5. احفظ

---

### 2. تحديث Data Safety Section
📍 **المكان:** App content > Data safety

**ما يجب تحديثه (إذا لم تكن قد أضفته):**

#### البيانات الجديدة التي يجب الإفصاح عنها:

**أ) البيانات الصحية (Health Data)**
- ✅ Heart Rate (معدل ضربات القلب)
- **السبب:** App functionality
- **التشفير:** نعم
- **يمكن حذفها:** نعم

**ب) بيانات الموقع في الخلفية**
- ✅ Background Location
- **السبب:** Emergency feature - لإرسال الموقع في حالات الطوارئ
- **التشفير:** نعم
- **مطلوب:** نعم (للميزة الأساسية)

**ج) الصور**
- ✅ Photos
- **السبب:** Profile picture
- **التشفير:** نعم
- **اختياري:** نعم

**د) معلومات الحساب**
- ✅ Name, Email, Phone
- **السبب:** Account management
- **التشفير:** نعم
- **مطلوب:** نعم

---

### 3. Background Location Declaration (مهم جداً!)
📍 **المكان:** App content > Sensitive app permissions > Background location

**إذا لم تكن قد ملأته، يجب ملؤه الآن:**

**السؤال 1:** Does your app access location in the background?
- ✅ Yes

**السؤال 2:** What core feature requires background location?
```
ميزة الطوارئ (Emergency Feature):
التطبيق مخصص لكبار السن ويوفر زر طوارئ يرسل موقعهم الفوري 
لجهات الاتصال الطارئة (الأقارب). لضمان عمل هذه الميزة حتى 
عندما لا يكون التطبيق مفتوحاً، نحتاج تتبع الموقع في الخلفية.
```

**السؤال 3:** How do users benefit?
```
- الشعور بالأمان لكبار السن
- إمكانية طلب المساعدة بضغطة زر
- راحة بال الأقارب والاطمئان على أحبائهم
- الوصول السريع في حالات الطوارئ
```

---

## 🔨 التعديلات المطلوبة في الكود

### 1. استبدال طلبات الأذونات القديمة

**ابحث في الكود عن:**
```dart
// الطريقة القديمة
await Permission.location.request();
await Permission.camera.request();
```

**استبدلها بـ:**
```dart
// الطريقة الجديدة (مع شاشة توضيحية)
await PermissionHelper.requestLocationPermission(context);
await PermissionHelper.requestCameraPermission(context);
```

---

### 2. إضافة رابط سياسة الخصوصية في التطبيق

**في شاشة الإعدادات أو "حول التطبيق":**

```dart
import 'package:url_launcher/url_launcher.dart';

// أضف هذا الثابت في أعلى الملف
const String privacyPolicyUrl = 'https://YOUR_USERNAME.github.io/sanadi-privacy/privacy-policy/';

// أضف هذه الدالة
Future<void> _openPrivacyPolicy() async {
  final uri = Uri.parse(privacyPolicyUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// في الـ Widget
ListTile(
  leading: Icon(Icons.privacy_tip),
  title: Text('سياسة الخصوصية'),
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: _openPrivacyPolicy,
),
```

---

### 3. إضافة خيار إيقاف التحليلات (Analytics)

**أنشئ ملف جديد:** `lib/features/profile/view/privacy_settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
    });
  }

  Future<void> _toggleAnalytics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', value);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
    
    setState(() {
      _analyticsEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'تم تفعيل جمع بيانات الاستخدام' 
          : 'تم إيقاف جمع بيانات الاستخدام'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الخصوصية'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('السماح بجمع بيانات الاستخدام'),
            subtitle: const Text('لتحسين التطبيق وإصلاح الأخطاء'),
            value: _analyticsEnabled,
            onChanged: _toggleAnalytics,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('حذف جميع بياناتي'),
            subtitle: const Text('حذف الحساب وجميع البيانات نهائياً'),
            onTap: () {
              // أضف منطق حذف الحساب
            },
          ),
        ],
      ),
    );
  }
}
```

**أضف رابط لهذه الشاشة في الإعدادات:**
```dart
ListTile(
  leading: Icon(Icons.security),
  title: Text('الخصوصية والأمان'),
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrivacySettingsScreen()),
    );
  },
),
```

---

## 📝 قائمة التحقق النهائية

قبل رفع التحديث على Google Play:

### الوثائق
- [ ] عدّلت معلومات الاتصال في `privacy-policy/index.html`
- [ ] رفعت المجلد على GitHub
- [ ] فعّلت GitHub Pages
- [ ] الرابط يعمل ويفتح الصفحة بشكل صحيح
- [ ] حدّثت رابط سياسة الخصوصية في Google Play Console

### الكود
- [ ] أضفت استخدام `PermissionHelper` في الأماكن المناسبة
- [ ] أضفت رابط سياسة الخصوصية في شاشة الإعدادات
- [ ] أضفت شاشة إعدادات الخصوصية
- [ ] أضفت خيار إيقاف Analytics

### Google Play Console
- [ ] حدّثت Data Safety Section
- [ ] ملأت Background Location Declaration (إذا لم يكن مملوءاً)
- [ ] تأكدت من صحة جميع المعلومات

### الاختبار
- [ ] اختبرت طلب الأذونات على جهاز حقيقي
- [ ] تأكدت من ظهور الشاشات التوضيحية
- [ ] اختبرت رابط سياسة الخصوصية
- [ ] اختبرت خيار إيقاف Analytics

---

## 🚀 خطوات الرفع

### 1. بناء التطبيق
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### 2. رفع على Google Play Console
1. اذهب إلى **Production** أو **Testing**
2. ارفع الـ AAB الجديد
3. أضف ملاحظات الإصدار:
   ```
   - تحسين نظام طلب الأذونات
   - إضافة شاشات توضيحية للأذونات
   - تحديث سياسة الخصوصية
   - إضافة إعدادات الخصوصية
   - تحسينات عامة في الأداء
   ```

### 3. المراجعة
- انتظر Pre-Launch Report
- تحقق من عدم وجود مشاكل
- إذا كان كل شيء جيد، اضغط **Submit for review**

---

## 📞 ملاحظات مهمة

### ⚠️ إذا كنت تستخدم ميزة الموقع في الخلفية:
- **يجب** ملء Background Location Declaration
- **يجب** أن يكون لديك سبب قوي ومقنع
- Google قد تطلب فيديو توضيحي

### ⚠️ إذا لم تكن تستخدم ميزة الموقع في الخلفية:
- احذف `ACCESS_BACKGROUND_LOCATION` من AndroidManifest.xml
- لا تطلب `Permission.locationAlways` في الكود

### ⚠️ البيانات الصحية:
- كن صريحاً في Data Safety Section
- أضف إخلاء المسؤولية الطبية بوضوح
- لا تدّعي أن التطبيق جهاز طبي

---

## ✅ الخلاصة

**ما تم إنشاؤه:**
1. ✅ ملف HTML لسياسة الخصوصية
2. ✅ نظام كامل لطلب الأذونات مع شاشات توضيحية
3. ✅ تحديث AndroidManifest.xml
4. ✅ أدلة شاملة للتنفيذ

**ما يجب عليك فعله:**
1. تعديل معلومات الاتصال في index.html
2. رفع سياسة الخصوصية على GitHub
3. إضافة استخدام نظام الأذونات في الكود
4. تحديث Google Play Console
5. بناء ورفع النسخة الجديدة

**الوقت المتوقع:** 2-3 ساعات عمل

---

**حظاً موفقاً! 🚀**

إذا احتجت أي توضيح إضافي، أنا هنا للمساعدة.
