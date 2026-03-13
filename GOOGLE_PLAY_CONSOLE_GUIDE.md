# 📱 دليل ملء نماذج Google Play Console

## 🎯 المرحلة 1: Data Safety Section

### الخطوات:
1. اذهب إلى Google Play Console
2. اختر تطبيقك
3. من القائمة الجانبية: **App content** > **Data safety**
4. اضغط **Start**

---

### البيانات المطلوب الإفصاح عنها:

#### 1️⃣ Location (الموقع)

**Does your app collect or share any of the following types of user data?**
- ✅ Yes

**Location data types:**
- ✅ Approximate location
- ✅ Precise location

**Is this data collected, shared, or both?**
- ✅ Collected
- ⬜ Shared

**Is this data processed ephemerally?**
- ⬜ Yes (لأننا نخزن الموقع)

**Is collection of this data required or optional?**
- ✅ Required (للميزات الأساسية)

**Why is this user data collected?**
- ✅ App functionality
- ✅ Analytics

**How is this data secured?**
- ✅ Data is encrypted in transit
- ✅ Data is encrypted at rest
- ✅ Users can request that data be deleted

---

#### 2️⃣ Health and fitness (البيانات الصحية)

**Does your app collect or share any of the following types of user data?**
- ✅ Yes

**Health and fitness data types:**
- ✅ Health info (Medication records, Medical appointments)

**ملاحظة:** لا تضف Heart Rate لأنك لم تستخدم هذه الميزة

**Is this data collected, shared, or both?**
- ✅ Collected
- ⬜ Shared

**Is this data processed ephemerally?**
- ⬜ No

**Is collection of this data required or optional?**
- ✅ Required (لتذكير الأدوية والمواعيد)

**Why is this user data collected?**
- ✅ App functionality

**How is this data secured?**
- ✅ Data is encrypted in transit
- ✅ Data is encrypted at rest
- ✅ Users can request that data be deleted

---

#### 3️⃣ Personal info (المعلومات الشخصية)

**Does your app collect or share any of the following types of user data?**
- ✅ Yes

**Personal info data types:**
- ✅ Name
- ✅ Email address
- ✅ User IDs
- ✅ Phone number

**Is this data collected, shared, or both?**
- ✅ Collected
- ✅ Shared (مع Firebase و Facebook)

**Is this data processed ephemerally?**
- ⬜ No

**Is collection of this data required or optional?**
- ✅ Required

**Why is this user data collected?**
- ✅ App functionality
- ✅ Account management

**How is this data secured?**
- ✅ Data is encrypted in transit
- ✅ Data is encrypted at rest
- ✅ Users can request that data be deleted

---

#### 4️⃣ Photos and videos (الصور)

**Does your app collect or share any of the following types of user data?**
- ✅ Yes

**Photos and videos data types:**
- ✅ Photos

**Is this data collected, shared, or both?**
- ✅ Collected
- ⬜ Shared

**Is this data processed ephemerally?**
- ⬜ No

**Is collection of this data required or optional?**
- ⬜ Required
- ✅ Optional

**Why is this user data collected?**
- ✅ App functionality (Profile picture)

**How is this data secured?**
- ✅ Data is encrypted in transit
- ✅ Users can request that data be deleted

---

#### 5️⃣ App activity (نشاط التطبيق)

**Does your app collect or share any of the following types of user data?**
- ✅ Yes

**App activity data types:**
- ✅ App interactions
- ✅ In-app search history

**Is this data collected, shared, or both?**
- ✅ Collected
- ✅ Shared (مع Firebase Analytics)

**Is this data processed ephemerally?**
- ⬜ No

**Is collection of this data required or optional?**
- ⬜ Required
- ✅ Optional (يمكن إيقافه)

**Why is this user data collected?**
- ✅ Analytics
- ✅ App functionality

---

#### 6️⃣ Device or other IDs (معرفات الجهاز)

**Does your app collect or share any of the following types of user data?**
- ✅ Yes

**Device or other IDs data types:**
- ✅ Device or other IDs

**Is this data collected, shared, or both?**
- ✅ Collected
- ✅ Shared (مع Firebase)

**Is this data processed ephemerally?**
- ⬜ No

**Is collection of this data required or optional?**
- ✅ Required

**Why is this user data collected?**
- ✅ Analytics
- ✅ Fraud prevention, security, and compliance

---

## 🎯 المرحلة 2: Background Location Declaration

### الخطوات:
1. من القائمة الجانبية: **App content** > **Sensitive app permissions**
2. اختر **Background location**
3. املأ النموذج

---

### الإجابات المقترحة:

**1. Does your app access location in the background?**
- ✅ Yes

**2. What core feature(s) in your app require access to location in the background?**

```
ميزة الطوارئ (Emergency Feature):
التطبيق مخصص لكبار السن ويوفر ميزة طوارئ تتيح لهم إرسال موقعهم الفوري 
لجهات الاتصال الطارئة (الأقارب) عند الضغط على زر الطوارئ. 

لضمان عمل هذه الميزة بشكل صحيح، يحتاج التطبيق لتتبع الموقع في الخلفية 
حتى عندما لا يكون التطبيق مفتوحاً، لأن حالات الطوارئ قد تحدث في أي وقت.

هذه ميزة أساسية لسلامة المستخدمين وراحة بال عائلاتهم.
```

**3. How does your app use location in the background?**

```
- تتبع موقع المستخدم بشكل دوري في الخلفية
- عند الضغط على زر الطوارئ، يُرسل الموقع الحالي فوراً لجهات الاتصال
- يمكن للأقارب رؤية آخر موقع معروف للمستخدم
- التتبع يعمل فقط عندما يفعّل المستخدم ميزة الطوارئ
```

**4. How do users benefit from this feature?**

```
الفوائد للمستخدمين (كبار السن):
- الشعور بالأمان لأنهم يعرفون أن المساعدة ستصل بسرعة
- إمكانية طلب المساعدة بضغطة زر واحدة
- عدم الحاجة لشرح موقعهم في حالات الطوارئ

الفوائد للأقارب:
- راحة البال والاطمئان على أحبائهم
- القدرة على الوصول السريع في حالات الطوارئ
- معرفة الموقع الدقيق لإرسال المساعدة
```

**5. Provide a YouTube video link showing the feature in action**
- [قم بإنشاء فيديو قصير يوضح الميزة]

---

## 🎯 المرحلة 3: Permissions Declaration

### الخطوات:
1. من القائمة الجانبية: **App content** > **App access**
2. املأ تفاصيل كل إذن

---

### شرح الأذونات:

**ACCESS_FINE_LOCATION & ACCESS_COARSE_LOCATION:**
```
لتحديد موقع المستخدم على الخريطة وإرسال الموقع في حالات الطوارئ.
```

**ACCESS_BACKGROUND_LOCATION:**
```
لتتبع موقع المستخدم في الخلفية لضمان عمل ميزة الطوارئ حتى عندما 
لا يكون التطبيق مفتوحاً.
```

**POST_NOTIFICATIONS:**
```
لإرسال تذكيرات بمواعيد الأدوية والمواعيد الطبية.
```

**READ_MEDIA_IMAGES:**
```
لاختيار صورة من معرض الصور لاستخدامها كصورة ملف شخصي.
```

**RECEIVE_BOOT_COMPLETED:**
```
لإعادة جدولة تذكيرات الأدوية بعد إعادة تشغيل الجهاز.
```

**SCHEDULE_EXACT_ALARM:**
```
لضمان دقة تذكيرات الأدوية في الوقت المحدد.
```

---

## 🎯 المرحلة 4: Privacy Policy

### الخطوات:
1. من القائمة الجانبية: **App content** > **Privacy policy**
2. أضف رابط سياسة الخصوصية

---

### خيارات رفع سياسة الخصوصية:

#### الخيار 1: GitHub Pages (مجاني)
1. أنشئ repository جديد في GitHub
2. ارفع ملف `privacy_policy_ar.md`
3. فعّل GitHub Pages من Settings
4. استخدم الرابط: `https://username.github.io/repo-name/privacy_policy_ar.html`

#### الخيار 2: موقعك الخاص
- ارفع الملف على موقعك
- استخدم رابط مثل: `https://yourwebsite.com/privacy-policy`

#### الخيار 3: خدمات مجانية
- **Termly**: https://termly.io
- **PrivacyPolicies**: https://www.privacypolicies.com
- **FreePrivacyPolicy**: https://www.freeprivacypolicy.com

---

## 🎯 المرحلة 5: Target Audience and Content

### الخطوات:
1. من القائمة الجانبية: **App content** > **Target audience and content**

---

### الإجابات:

**Target age:**
- ✅ 18 and over

**Does your app appeal to children?**
- ⬜ No

**Content rating:**
- املأ الاستبيان بصدق
- التطبيق الصحي عادة يحصل على تصنيف "Everyone" أو "Teen"

---

## 🎯 المرحلة 6: Ads Declaration

**Does your app contain ads?**
- ⬜ No (إذا لم تضف إعلانات)
- ✅ Yes (إذا أضفت AdMob أو غيره)

---

## 🎯 المرحلة 7: Store Listing

### معلومات مهمة:

**App name:**
```
سندي - رعاية كبار السن
```

**Short description (80 characters):**
```
تطبيق شامل لرعاية كبار السن: تذكير بالأدوية، طوارئ، مواعيد طبية
```

**Full description (4000 characters):**
```
🌟 سندي - رفيقك لحياة سعيدة ومطمئنة

سندي هو تطبيق شامل مصمم خصيصاً لكبار السن وعائلاتهم، يوفر جميع 
الأدوات اللازمة للعناية الصحية والاطمئنان على أحبائك.

✨ الميزات الرئيسية:

💊 تذكير بالأدوية
• جدولة مواعيد الأدوية بسهولة
• تنبيهات دقيقة في الوقت المحدد
• تتبع تاريخ تناول الأدوية

🚨 نظام الطوارئ
• زر طوارئ سريع
• إرسال الموقع الفوري لجهات الاتصال
• تتبع الموقع للاطمئنان

👨‍⚕️ حجز المواعيد الطبية
• البحث عن الأطباء القريبين
• حجز المواعيد بسهولة
• تذكير بالمواعيد القادمة

🛒 خدمة البقالة
• طلب احتياجاتك اليومية
• توصيل سريع للمنزل
• دفع آمن

🏃 تمارين رياضية
• تمارين مناسبة لكبار السن
• فيديوهات توضيحية
• تتبع التقدم

📱 واجهة سهلة الاستخدام
• تصميم بسيط وواضح
• خطوط كبيرة وقابلة للقراءة
• دعم اللغة العربية والإنجليزية

🔒 الخصوصية والأمان
• بياناتك مشفرة ومحمية
• لا نشارك معلوماتك مع أي طرف ثالث
• يمكنك حذف بياناتك في أي وقت

⚠️ تنبيه مهم:
سندي ليس بديلاً عن الاستشارة الطبية المهنية. استشر طبيبك دائماً 
قبل اتخاذ أي قرارات صحية.

📧 تواصل معنا:
[بريدك الإلكتروني]

💙 سندي - لأن راحتك وراحة عائلتك تهمنا
```

---

## 📸 Screenshots Requirements

**يجب توفير:**
- 2-8 screenshots للهواتف
- 2-8 screenshots للتابلت (اختياري)

**المقاسات:**
- Phone: 16:9 aspect ratio (1080x1920 recommended)
- Tablet: 16:9 or 16:10

**نصائح:**
- أضف نصوص توضيحية على الصور
- أظهر الميزات الرئيسية
- استخدم صور واقعية من التطبيق

---

## 🎬 Feature Graphic

**المقاس:** 1024 x 500 pixels  
**الصيغة:** PNG or JPEG  
**الحجم:** Max 1MB

---

## 🎯 نصائح نهائية

✅ **قبل الرفع:**
1. اختبر التطبيق على أجهزة مختلفة
2. تأكد من عمل جميع الأذونات بشكل صحيح
3. راجع جميع النصوص والترجمات
4. تأكد من رفع سياسة الخصوصية

✅ **بعد الرفع:**
1. راقب Pre-Launch Report
2. أصلح أي مشاكل مكتشفة
3. اختبر على Internal Testing أولاً
4. ثم انتقل لـ Closed Testing
5. أخيراً Production

---

**حظاً موفقاً! 🚀**
