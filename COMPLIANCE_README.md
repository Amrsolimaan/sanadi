# 🎯 دليل التوافق الشامل مع Google Play - تطبيق سندي

## 📋 نظرة عامة

هذا الدليل يحتوي على جميع الملفات والتعليمات اللازمة لجعل تطبيق سندي متوافقاً 100% مع سياسات Google Play Store.

---

## 📁 الملفات المُنشأة

### 1. الوثائق القانونية
- ✅ `privacy_policy_ar.md` - سياسة الخصوصية بالعربية
- ✅ `privacy_policy_en.md` - سياسة الخصوصية بالإنجليزية
- ✅ `terms_of_service_ar.md` - شروط الخدمة بالعربية

### 2. نظام الأذونات
- ✅ `lib/features/permissions/model/permission_info.dart` - نموذج معلومات الإذن
- ✅ `lib/features/permissions/view/permission_request_screen.dart` - شاشة طلب الأذونات
- ✅ `lib/features/permissions/view/background_location_permission_screen.dart` - شاشة خاصة للموقع في الخلفية
- ✅ `lib/features/permissions/utils/permission_helper.dart` - مساعد الأذونات

### 3. الأدلة والخطط
- ✅ `GOOGLE_PLAY_COMPLIANCE_PLAN.md` - خطة الإصلاح المتكاملة
- ✅ `GOOGLE_PLAY_CONSOLE_GUIDE.md` - دليل ملء نماذج Google Play Console
- ✅ `COMPLIANCE_README.md` - هذا الملف

### 4. التعديلات على الملفات الموجودة
- ✅ `android/app/src/main/AndroidManifest.xml` - تحديث الأذونات

---

## 🚀 خطوات التنفيذ السريعة

### المرحلة 1: رفع سياسة الخصوصية (عاجل جداً)

#### الخيار الأول: GitHub Pages (مجاني وسريع)

```bash
# 1. أنشئ repository جديد في GitHub
# اسم مقترح: sanadi-privacy-policy

# 2. ارفع الملفات
git init
git add privacy_policy_ar.md privacy_policy_en.md terms_of_service_ar.md
git commit -m "Add privacy policy and terms"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/sanadi-privacy-policy.git
git push -u origin main

# 3. فعّل GitHub Pages
# اذهب إلى Settings > Pages
# اختر branch: main
# اختر folder: / (root)
# احفظ

# 4. الرابط سيكون:
# https://YOUR_USERNAME.github.io/sanadi-privacy-policy/privacy_policy_ar.html
```

#### الخيار الثاني: استخدام خدمة مجانية

1. اذهب إلى https://www.freeprivacypolicy.com
2. أنشئ حساب مجاني
3. انسخ محتوى `privacy_policy_ar.md`
4. الصقه في الموقع
5. احصل على الرابط

---

### المرحلة 2: تحديث التطبيق

#### 1. إضافة استخدام نظام الأذونات

في أي مكان تحتاج فيه طلب إذن، استخدم:

```dart
import 'package:sanadi/features/permissions/utils/permission_helper.dart';

// مثال: طلب إذن الموقع
final granted = await PermissionHelper.requestLocationPermission(context);
if (granted) {
  // المستخدم منح الإذن
} else {
  // المستخدم رفض الإذن
}

// مثال: طلب إذن الموقع في الخلفية
final granted = await PermissionHelper.requestBackgroundLocationPermission(context);

// مثال: طلب إذن الكاميرا
final granted = await PermissionHelper.requestCameraPermission(context);

// مثال: طلب إذن الإشعارات
final granted = await PermissionHelper.requestNotificationPermission(context);
```

#### 2. إضافة روابط سياسة الخصوصية في التطبيق

أضف في شاشة الإعدادات أو "حول التطبيق":

```dart
import 'package:url_launcher/url_launcher.dart';

// رابط سياسة الخصوصية
const privacyPolicyUrl = 'https://YOUR_USERNAME.github.io/sanadi-privacy-policy/privacy_policy_ar.html';

// فتح الرابط
Future<void> openPrivacyPolicy() async {
  final uri = Uri.parse(privacyPolicyUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

#### 3. إضافة خيار إيقاف Firebase Analytics

في ملف `lib/features/profile/view/privacy_settings_screen.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  // ... existing code
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsPreference();
  }

  Future<void> _loadAnalyticsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
    });
  }

  Future<void> _toggleAnalytics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', value);
    
    // تفعيل/تعطيل Firebase Analytics
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
    
    setState(() {
      _analyticsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إعدادات الخصوصية')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('السماح بجمع بيانات الاستخدام'),
            subtitle: Text('لتحسين التطبيق وإصلاح الأخطاء'),
            value: _analyticsEnabled,
            onChanged: _toggleAnalytics,
          ),
          // ... other settings
        ],
      ),
    );
  }
}
```

---

### المرحلة 3: ملء نماذج Google Play Console

اتبع الدليل الموجود في `GOOGLE_PLAY_CONSOLE_GUIDE.md` خطوة بخطوة.

**الأقسام المطلوبة:**
1. ✅ Data Safety Section
2. ✅ Background Location Declaration
3. ✅ Permissions Declaration
4. ✅ Privacy Policy URL
5. ✅ Target Audience
6. ✅ Content Rating

---

### المرحلة 4: الاختبار

#### 1. اختبار الأذونات

```bash
# بناء التطبيق
flutter build apk --release

# أو للاختبار
flutter run --release
```

**اختبر:**
- ✅ طلب كل إذن يظهر الشاشة التوضيحية
- ✅ رفض الإذن لا يعطل التطبيق
- ✅ الأذونات تعمل بعد المنح
- ✅ زر "فتح الإعدادات" يعمل

#### 2. اختبار على أجهزة مختلفة

- Android 10 (API 29)
- Android 11 (API 30)
- Android 12 (API 31)
- Android 13+ (API 33+)

---

### المرحلة 5: الرفع على Google Play

#### 1. Internal Testing أولاً

```bash
# بناء App Bundle
flutter build appbundle --release

# الملف سيكون في:
# build/app/outputs/bundle/release/app-release.aab
```

1. اذهب إلى Google Play Console
2. اختر **Testing** > **Internal testing**
3. ارفع الـ AAB
4. أضف مختبرين (بريدهم الإلكتروني)
5. انتظر Pre-Launch Report

#### 2. مراجعة Pre-Launch Report

- تحقق من عدم وجود crashes
- تحقق من عدم وجود تحذيرات أمنية
- أصلح أي مشاكل

#### 3. الانتقال لـ Production

بعد التأكد من عدم وجود مشاكل:
1. اذهب إلى **Production**
2. ارفع نفس الـ AAB
3. املأ جميع المعلومات المطلوبة
4. اضغط **Submit for review**

---

## ⚠️ نقاط مهمة جداً

### 1. إذن الموقع في الخلفية

**Google Play صارم جداً في هذا الإذن!**

✅ **يجب:**
- شرح واضح ومفصل للمستخدم
- ميزة أساسية تتطلب هذا الإذن
- فيديو يوضح الاستخدام (مستحسن)

❌ **لا تفعل:**
- طلب الإذن بدون شرح
- استخدامه لأغراض غير ضرورية
- جمع البيانات بدون علم المستخدم

### 2. البيانات الصحية

**حساسة جداً!**

✅ **يجب:**
- إخلاء مسؤولية طبية واضح
- تشفير البيانات
- عدم مشاركتها بدون موافقة

❌ **لا تفعل:**
- الادعاء بأن التطبيق جهاز طبي
- تقديم نصائح طبية
- استخدام البيانات لأغراض تجارية

### 3. سياسة الخصوصية

✅ **يجب:**
- رابط يعمل ومتاح دائماً
- محتوى واضح وشامل
- تحديثها عند تغيير جمع البيانات

❌ **لا تفعل:**
- استخدام رابط لا يعمل
- نسخ سياسة من تطبيق آخر
- إخفاء معلومات مهمة

---

## 🔍 قائمة التحقق النهائية

قبل الرفع، تأكد من:

### الوثائق
- [ ] سياسة الخصوصية مرفوعة ورابطها يعمل
- [ ] شروط الخدمة متوفرة
- [ ] إخلاء المسؤولية الطبية واضح

### الأذونات
- [ ] كل إذن له شاشة توضيحية
- [ ] إذن الموقع في الخلفية له شرح مفصل
- [ ] التطبيق يعمل عند رفض الأذونات غير المطلوبة

### Google Play Console
- [ ] Data Safety Section مملوء بالكامل
- [ ] Background Location Declaration مملوء
- [ ] Privacy Policy URL مضاف
- [ ] Screenshots مرفوعة (2-8 صور)
- [ ] Feature Graphic مرفوع
- [ ] App description مكتوب بشكل جيد

### الاختبار
- [ ] اختبار على Android 10+
- [ ] اختبار على Android 13+
- [ ] Pre-Launch Report بدون مشاكل
- [ ] Internal Testing ناجح

### الأمان
- [ ] البيانات مشفرة
- [ ] Firebase Rules محدثة
- [ ] لا توجد API keys مكشوفة في الكود

---

## 📞 الدعم والمساعدة

### إذا واجهت مشاكل:

**1. رفض التطبيق بسبب الأذونات:**
- راجع `GOOGLE_PLAY_CONSOLE_GUIDE.md`
- تأكد من ملء Background Location Declaration
- أضف فيديو توضيحي

**2. مشاكل في Data Safety:**
- كن صادقاً في الإفصاح عن البيانات
- لا تخفي أي بيانات تجمعها
- راجع سياسة الخصوصية

**3. مشاكل تقنية:**
- راجع Pre-Launch Report
- اختبر على أجهزة حقيقية
- استخدم `flutter doctor` للتحقق من البيئة

### موارد مفيدة:

- [Google Play Policy Center](https://play.google.com/about/developer-content-policy/)
- [Data Safety Help](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Background Location Best Practices](https://developer.android.com/training/location/permissions)
- [Flutter Permission Handler](https://pub.dev/packages/permission_handler)

---

## 📊 الجدول الزمني المتوقع

| المرحلة | الوقت المقدر | الأولوية |
|---------|--------------|----------|
| رفع سياسة الخصوصية | 1-2 ساعة | 🔴 عاجل |
| تحديث AndroidManifest | 30 دقيقة | 🔴 عاجل |
| إضافة شاشات الأذونات | 3-4 ساعات | 🔴 عاجل |
| ملء Google Play Console | 2-3 ساعات | 🔴 عاجل |
| الاختبار | 2-3 ساعات | 🟠 مهم |
| Internal Testing | 1-2 يوم | 🟠 مهم |
| المراجعة والرفع | 3-7 أيام | 🟡 عادي |

**إجمالي الوقت المتوقع:** 5-7 أيام من البداية للنشر

---

## ✅ الخلاصة

تم إنشاء جميع الملفات والأدوات اللازمة لجعل تطبيق سندي متوافقاً مع Google Play. 

**الخطوات التالية:**
1. ارفع سياسة الخصوصية على GitHub Pages أو موقعك
2. أضف استخدام نظام الأذونات في التطبيق
3. املأ نماذج Google Play Console
4. اختبر التطبيق بشكل شامل
5. ارفع على Internal Testing
6. بعد التأكد، ارفع على Production

**حظاً موفقاً! 🚀**

إذا احتجت أي مساعدة إضافية، لا تتردد في السؤال.

---

**تم إنشاء هذا الدليل في:** 4 مارس 2026  
**الإصدار:** 1.0  
**الحالة:** ✅ جاهز للتنفيذ
