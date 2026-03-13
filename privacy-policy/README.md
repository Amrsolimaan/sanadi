# سياسة الخصوصية - تطبيق سندي

## 📋 نظرة عامة
هذا المجلد يحتوي على سياسة الخصوصية لتطبيق سندي بصيغة HTML.

## 📁 الملفات
- `index.html` - سياسة الخصوصية بالعربية (الصفحة الرئيسية)

## 🚀 كيفية الرفع على GitHub Pages

### الخطوة 1: إنشاء Repository
```bash
# في مجلد المشروع
git init
git add privacy-policy/
git commit -m "Add privacy policy"
git branch -M main
```

### الخطوة 2: رفع على GitHub
```bash
# استبدل YOUR_USERNAME باسم المستخدم الخاص بك
git remote add origin https://github.com/YOUR_USERNAME/sanadi-privacy.git
git push -u origin main
```

### الخطوة 3: تفعيل GitHub Pages
1. اذهب إلى repository على GitHub
2. اضغط على **Settings**
3. من القائمة الجانبية، اختر **Pages**
4. في **Source**، اختر:
   - Branch: `main`
   - Folder: `/ (root)`
5. اضغط **Save**
6. انتظر دقيقة واحدة

### الخطوة 4: الحصول على الرابط
الرابط سيكون:
```
https://YOUR_USERNAME.github.io/sanadi-privacy/privacy-policy/
```

## ✏️ التعديلات المطلوبة

قبل الرفع، افتح `index.html` وعدّل:

1. **البريد الإلكتروني:**
   - ابحث عن: `[أضف بريدك الإلكتروني]`
   - استبدله بـ: بريدك الفعلي

2. **الموقع الإلكتروني:**
   - ابحث عن: `[أضف موقعك]`
   - استبدله بـ: رابط موقعك (أو احذف السطر إذا لم يكن لديك)

3. **العنوان:**
   - ابحث عن: `[أضف عنوانك]`
   - استبدله بـ: عنوانك (أو احذف السطر)

4. **البلد:**
   - ابحث عن: `[بلدك]`
   - استبدله بـ: اسم بلدك

## 🔗 استخدام الرابط

بعد الرفع، استخدم الرابط في:
1. **Google Play Console** > App content > Privacy policy
2. **داخل التطبيق** في شاشة الإعدادات أو "حول التطبيق"

## 📱 إضافة الرابط في التطبيق

```dart
import 'package:url_launcher/url_launcher.dart';

const String privacyPolicyUrl = 'https://YOUR_USERNAME.github.io/sanadi-privacy/privacy-policy/';

Future<void> openPrivacyPolicy() async {
  final uri = Uri.parse(privacyPolicyUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

## ✅ التحقق

بعد الرفع، تأكد من:
- [ ] الرابط يعمل ويفتح الصفحة
- [ ] الصفحة تظهر بشكل صحيح على الموبايل
- [ ] جميع المعلومات صحيحة ومحدثة
- [ ] لا توجد أخطاء في النص

## 🔄 التحديثات المستقبلية

عند تحديث سياسة الخصوصية:
1. عدّل ملف `index.html`
2. غيّر تاريخ "آخر تحديث" في أعلى الصفحة
3. ارفع التغييرات:
   ```bash
   git add privacy-policy/index.html
   git commit -m "Update privacy policy"
   git push
   ```
4. الصفحة ستتحدث تلقائياً خلال دقائق

---

**ملاحظة:** احتفظ بهذا الرابط في مكان آمن، ستحتاجه في Google Play Console.
