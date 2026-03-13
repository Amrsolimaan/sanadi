# 📋 تقسيم الميزات (Features Breakdown)

## 🏗️ البنية العامة
```
lib/features/
├── auth/                    # المصادقة
├── profile/                # الملف الشخصي
├── home/                   # الشاشة الرئيسية
├── medications/            # الأدوية
├── doctors/                # الأطباء
├── emergency/              # الطوارئ
├── location/               # الموقع
├── health/                 # الصحة
├── grocery/                # التسوق
├── grocery_admin/          # لوحة الأدمن
├── permissions/            # الأذونات
├── services/               # الخدمات
├── favorites/              # المفضلة
├── records/                # السجلات
├── shoping/                # التسوق العام
├── splash/                 # شاشة البداية
└── onboarding/             # التعريف بالتطبيق
```

---

## 1️⃣ **Authentication (المصادقة)**
**الملفات:**
```
lib/features/auth/
├── model/
│   └── user_model.dart          # نموذج بيانات المستخدم
├── view/
│   ├── login_screen.dart        # تسجيل الدخول
│   ├── sign_up_screen.dart      # إنشاء حساب
│   ├── forgot_password_screen.dart  # نسيان كلمة المرور
│   ├── otp_screen.dart          # التحقق بالرمز
│   └── reset_password_screen.dart   # إعادة تعيين كلمة المرور
└── viewmodel/
    ├── auth_cubit.dart          # إدارة حالة المصادقة
    └── auth_state.dart          # حالات المصادقة
```

**الخدمات:**
```
lib/services/auth/auth_service.dart
```

**التقنيات المستخدمة:**
- Firebase Authentication
- Google Sign-In SDK
- Facebook Auth SDK
- Phone number verification (OTP)
- Email/password authentication

**الوظائف:**
- تسجيل دخول بالبريد/كلمة المرور
- تسجيل دخول بـ Google
- تسجيل دخول بـ Facebook
- التحقق من رقم الهاتف (OTP)
- إعادة تعيين كلمة المرور
- حفظ حالة تسجيل الدخول

**نقاط تقنية مهمة:**
- التعامل مع حالات الخطأ المختلفة
- التحقق من صحة البيانات المدخلة
- تخزين بيانات المستخدم في Firestore بعد التسجيل
- إدارة جلسات المستخدم

---

## 2️⃣ **Profile Management (إدارة الملف الشخصي)**
**الملفات:**
```
lib/features/profile/
├── model/
│   └── profile_model.dart       # نموذج البروفايل
├── view/
│   ├── profile_screen.dart      # شاشة البروفايل
│   ├── personal_details_screen.dart  # التفاصيل الشخصية
│   └── edit_profile_screen.dart # تعديل البروفايل
└── viewmodel/
    ├── profile_cubit.dart       # إدارة حالة البروفايل
    └── profile_state.dart       # حالات البروفايل
```

**الخدمات:**
```
lib/services/firestore/user_service.dart
lib/services/supabase_storage_service.dart
```

**التقنيات المستخدمة:**
- Supabase Storage (لتخزين الصور)
- Image Picker (اختيار الصور)
- Image Compression (ضغط الصور)
- Cached Network Image (تخزين مؤقت للصور)
- Shared Preferences (تخزين محلي)

**الوظائف:**
- عرض وتعديل البيانات الشخصية
- رفع وحذف الصورة الشخصية
- تحديث معلومات الاتصال
- إدارة الصلاحيات (Admin/User)
- حفظ التفضيلات المحلية

**نقاط تقنية مهمة:**
- ضغط الصور قبل الرفع لتوفير bandwidth
- Cache management للصور
- التعامل مع Supabase Storage
- تحديث البيانات في الوقت الحقيقي

---

## 3️⃣ **Home (الشاشة الرئيسية)**
**الملفات:**
```
lib/features/home/
├── view/
│   └── home_screen.dart         # الشاشة الرئيسية
└── viewmodel/
    ├── home_cubit.dart          # إدارة حالة الشاشة الرئيسية
    └── home_state.dart          # حالات الشاشة الرئيسية
```

**التقنيات المستخدمة:**
- Responsive Design (Mobile + Desktop)
- Bottom Navigation
- Sidebar Navigation للشاشات الكبيرة
- Animation (SOS button)
- Search functionality

**الوظائف:**
- عرض واجهة المستخدم الرئيسية
- التنقل بين التابات
- البحث عن الأطباء والخدمات
- زر SOS متحرك
- عرض بيانات المستخدم
- دعم الشاشات الكبيرة (Desktop/Tablet)

**نقاط تقنية مهمة:**
- تصميم متجاوب (Responsive)
- إدارة حالة التنقل
- Animations للـ SOS button
- Integration مع باقي الميزات

---

## 4️⃣ **Medications (إدارة الأدوية) - ⭐ الميزة الأكثر تعقيداً**
**الملفات:**
```
lib/features/medications/
├── model/
│   ├── medication_model.dart        # نموذج الدواء
│   ├── medication_log_model.dart    # نموذج سجل الدواء
│   └── notification_event_model.dart # نموذج حدث الإشعار
├── view/
│   ├── medications_screen.dart      # قائمة الأدوية
│   ├── add_medication_screen.dart   # إضافة دواء
│   ├── edit_medication_screen.dart  # تعديل دواء
│   └── medication_details_screen.dart # تفاصيل الدواء
└── viewmodel/
    ├── medication_cubit.dart        # إدارة حالة الأدوية
    └── medication_state.dart        # حالات الأدوية
```

**الخدمات:**
```
lib/services/firestore/medication_service.dart
lib/services/firestore/alarm_service.dart
lib/services/firestore/persistent_alarm_service.dart
lib/services/firestore/notification_history_service.dart
```

**التقنيات المستخدمة:**
- Android Alarm Manager Plus (منبهات دقيقة)
- Flutter Local Notifications
- Timezone handling
- Firestore subcollections
- Background tasks

**الوظائف:**
- إضافة/تعديل/حذف الأدوية
- جدولة مواعيد الأدوية (يومي، أسبوعي، شهري)
- منبهات ذكية تعمل حتى مع إغلاق التطبيق
- تسجيل تناول/تخطي الدواء
- حساب نسبة الالتزام (Compliance Rate)
- إشعارات محلية
- سجل تاريخ تناول الأدوية

**نقاط تقنية مهمة:**
- إعادة جدولة المنبهات عند إعادة تشغيل الجهاز
- التعامل مع مناطق زمنية مختلفة
- Background services
- Local notifications
- Firestore subcollections structure

---

## 5️⃣ **Doctors & Appointments (الأطباء والمواعيد)**
**الملفات:**
```
lib/features/doctors/
├── model/
│   ├── doctor_model.dart          # نموذج الطبيب
│   ├── appointment_model.dart     # نموذج الموعد
│   └── specialty_model.dart       # نموذج التخصص
├── view/
│   ├── doctors_list_screen.dart   # قائمة الأطباء
│   ├── doctor_details_screen.dart # تفاصيل الطبيب
│   ├── booking_screen.dart        # حجز موعد
│   └── my_appointments_screen.dart # مواعيدي
└── viewmodel/
    ���── doctors_cubit.dart         # قائمة الأطباء
    ├── doctor_details_cubit.dart  # تفاصيل طبيب
    ├── booking_cubit.dart         # حجز موعد
    ├── appointments_cubit.dart    # المواعيد
    └── (states لكل cubit)
```

**الخدمات:**
```
lib/services/firestore/doctor_service.dart
lib/services/firestore/appointment_service.dart
lib/services/firestore/specialty_service.dart
lib/services/firestore/favorite_service.dart
lib/services/firestore/review_service.dart
```

**التقنيات المستخدمة:**
- Firestore queries with filters
- Search functionality
- Multi-language data
- Rating system
- Favorites system

**الوظائف:**
- عرض قائمة الأطباء
- البحث والفلترة حسب التخصص
- عرض تفاصيل الطبيب
- حجز موعد
- عرض المواعيد القادمة والسابقة
- نظام النقاط للأطباء الأكثر شعبية
- إضافة إلى المفضلة
- تقييم الأطباء

**نقاط تقنية مهمة:**
- 4 Cubits منفصلة (Separation of Concerns)
- البحث في بيانات متعددة اللغات
- نظام النقاط وترتيب الأطباء
- Firestore indexes للبحث

---

## 6️⃣ **Emergency System (نظام الطوارئ)**
**الملفات:**
```
lib/features/emergency/
├── model/
│   └── emergency_contact_model.dart  # نموذج جهة اتصال
├── view/
│   ├── emergency_contacts_screen.dart # جهات الاتصال
│   ├── add_emergency_contact_screen.dart # إضافة جهة
│   └── call_for_assistance_screen.dart # طلب المساعدة
└── viewmodel/
    ├── emergency_contacts_cubit.dart  # إدارة جهات الاتصال
    └── emergency_contacts_state.dart  # حالات جهات الاتصال
```

**الخدمات:**
```
lib/services/firestore/emergency_contact_service.dart
lib/services/location/location_service.dart
```

**التقنيات المستخدمة:**
- Geolocator (دقة عالية في الموقع)
- Background location services
- URL Launcher (الاتصال، WhatsApp)
- Foreground services
- Animation (SOS button)

**الوظائف:**
- إضافة جهات اتصال الطوارئ
- زر SOS متحرك
- إرسال الموقع الحالي
- الاتصال المباشر
- إرسال رسائل WhatsApp
- تتبع الموقع في الخلفية

**الأذونات المطلوبة:**
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- ACCESS_BACKGROUND_LOCATION
- FOREGROUND_SERVICE
- FOREGROUND_SERVICE_LOCATION

**نقاط تقنية مهمة:**
- الحصول على الموقع بدقة عالية
- التعامل مع أذونات الموقع في الخلفية
- Foreground services
- Privacy considerations

---

## 7️⃣ **Location Services (خدمات الموقع)**
**الملفات:**
```
lib/features/location/
└── viewmodel/
    ├── location_cubit.dart      # إدارة حالة الموقع
    └── location_state.dart      # حالات الموقع
```

**الخدمات:**
```
lib/services/location/location_service.dart
```

**التقنيات المستخدمة:**
- Geolocator package
- Background location updates
- Location permissions handling
- Battery optimization

**الوظائف:**
- الحصول على الموقع الحالي
- تحديث الموقع في الخلفية
- حفظ سجل المواقع
- إدارة أذونات الموقع

**نقاط تقنية مهمة:**
- Battery optimization
- Accuracy vs battery trade-off
- Permission handling
- Background execution

---

## 8️⃣ **Health & Exercises (الصحة والتمارين)**
**الملفات:**
```
lib/features/health/
├── model/
│   ├── exercise_model.dart      # نموذج التمرين
│   └── heart_rate_model.dart    # نموذج قياس ضربات القلب
├── view/
│   ├── health_exercises_screen.dart  # التمارين الصحية
│   ├── exercise_details_screen.dart  # تفاصيل التمرين
│   └── heart_rate_measure_screen.dart # قياس ضربات القلب
└── viewmodel/
    ├── health_cubit.dart        # إدارة حالة الصحة
    └── health_state.dart        # حالات الصحة
```

**الخدمات:**
```
lib/services/firestore/health_service.dart
lib/services/firestore/heart_rate_service.dart
```

**التقنيات المستخدمة:**
- Multi-language data structure
- Timer for exercises
- Exercise instructions
- Health data visualization

**الوظائف:**
- تمارين التنفس (Breathing)
- تمارين الإطالة (Stretching)
- التأمل (Meditation)
- اليوغا (Yoga)
- تعليمات مفصلة لكل تمرين
- دعم متعدد اللغات

**نقاط تقنية مهمة:**
- نموذج بيانات متعدد اللغات
- Timers للتمارين
- تعليمات تفاعلية
- Health data management

---

## 9️⃣ **Grocery Shopping (التسوق) - ⚠️ قيد التطوير**
**الملفات:**
```
lib/features/grocery/
├── model/
│   ├── product_model.dart       # نموذج المنتج
│   ├── category_model.dart      # نموذج الفئة
│   ├── cart_model.dart          # نموذج السلة
│   └── order_model.dart         # نموذج الطلب
├── view/
│   ├── grocery_home_screen.dart # الصفحة الرئيسية
│   ├── category_products_screen.dart # منتجات الفئة
│   ├── product_details_screen.dart # تفاصيل المنتج
│   ├── cart_screen.dart         # سلة التسوق
│   └── order_screen.dart        # الطلبات
└── viewmodel/
    ├── grocery_cubit.dart       # المنتجات
    ├── category_products_cubit.dart # منتجات الفئة
    ├── product_details_cubit.dart # تفاصيل المنتج
    ├── cart_cubit.dart          # السلة
    ├── order_cubit.dart         # الطلبات
    ├── order_history_cubit.dart # سجل الطلبات
    └── reorder_cubit.dart       # إعادة الطلب
```

**الخدمات:**
```
lib/services/firestore/grocery_service.dart
```

**التقنيات المستخدمة:**
- Firestore for product catalog
- Shopping cart logic
- Order management
- Payment integration (مخطط)

**الوظائف المخططة:**
- عرض المنتجات
- سلة التسوق
- إتمام الطلبات
- تتبع الطلبات
- سجل المشتريات

**الحالة الحالية:**
- البنية الأساسية موجودة
- Cubits جاهزة
- يحتاج UI completion

---

## 🔟 **Grocery Admin (لوحة الأدمن)**
**الملفات:**
```
lib/features/grocery_admin/
├── view/
│   └── admin_dashboard_screen.dart  # لوحة التحكم
└── viewmodel/
    ├── admin_cubit.dart          # إدارة حالة الأدمن
    └── admin_state.dart          # حالات الأدمن
```

**الخدمات:**
```
lib/services/firestore/admin_service_addition.dart
```

**التقنيات المستخدمة:**
- Role-based access control
- Admin-specific UI
- Product management
- Order management

**الوظائف:**
- إدارة المنتجات
- إدارة الطلبات
- إدارة المستخدمين
- إحصائيات المبيعات

**نقاط تقنية مهمة:**
- التحقق من صلاحيات الأدمن
- واجهة مختلفة للمسؤولين
- إدارة البي��نات الحساسة

---

## 1️⃣1️⃣ **Permissions System (نظام الأذونات)**
**الملفات:**
```
lib/features/permissions/
├── model/
│   └── permission_info.dart     # معلومات الإذن
├── view/
│   ├── permission_request_screen.dart      # طلب الإذن
│   └── background_location_permission_screen.dart # إذن الموقع في الخلفية
└── utils/
    └── permission_helper.dart   # مساعد الأذونات
```

**التقنيات المستخدمة:**
- Permission Handler package
- Custom permission screens
- Runtime permission requests
- Permission status tracking

**الأذونات المدارة:**
- الموقع (Location)
- الموقع في الخلفية (Background Location)
- الإشعارات (Notifications)
- الصور (Photos)
- الكاميرا (مستقبلي)

**نقاط تقنية مهمة:**
- شاشات طلب أذونات مخص��ة
- التوافق مع Google Play policies
- Graceful degradation
- Permission explanation screens

---

## 1️⃣2️⃣ **Services (الخدمات)**
**الملفات:**
```
lib/features/services/
└── view/
    └── services_screen.dart     # شاشة الخدمات
```

**الوظائف:**
- عرض قائمة الخدمات المتاحة
- التنقل للخدمات المختلفة

---

## 1️⃣3️⃣ **Favorites (المفضلة)**
**الملفات:**
```
lib/features/favorites/
└── (الهيكل الأساسي موجود)
```

**الخدمات:**
```
lib/services/firestore/favorite_service.dart
```

**الوظائف:**
- إضافة/حذف من المفضلة
- عرض العناصر المفضلة

---

## 1️⃣4️⃣ **Records (السجلات)**
**الملفات:**
```
lib/features/records/
└── (الهيكل الأساسي موجود)
```

**الوظائف:**
- تخزين وعرض السجلات الطبية

---

## 1️⃣5️⃣ **Shopping (التسوق العام)**
**الملفات:**
```
lib/features/shoping/
└── viewmodel/
    ├── shopping_cubit.dart      # إدارة حالة التسوق
    └── shopping_state.dart      # حالات التسوق
```

**الوظائف:**
- إدارة عمليات التسوق العامة

---

## 1️⃣6️⃣ **Splash (شاشة البداية)**
**الملفات:**
```
lib/features/splash/
└── view/
    └── splash_screen.dart       # شاشة البداية
```

**الوظائف:**
- عرض شاشة البداية
- التهيئة الأولية للتطبيق
- التوجيه للشاشة المناسبة

---

## 1️⃣7️⃣ **Onboarding (التعريف بالتطبيق)**
**الملفات:**
```
lib/features/onboarding/
└── (الهيكل الأساسي موجود)
```

**الوظائف:**
- شرح ميزات التطبيق للمستخدمين الجدد

---

## 📊 ملخص التقنيات المستخدمة في كل ميزة

### **Authentication:**
- Firebase Auth, Google Sign-In, Facebook Auth, OTP

### **Profile:**
- Supabase Storage, Image Picker, Image Compression, Cached Images

### **Medications:**
- Android Alarm Manager, Local Notifications, Timezone, Background Tasks

### **Doctors:**
- Firestore Queries, Search, Multi-language, Rating System

### **Emergency:**
- Geolocator, Background Location, URL Launcher, Foreground Services

### **Location:**
- Geolocator, Background Updates, Permission Handling

### **Health:**
- Multi-language Models, Timers, Exercise Instructions

### **Grocery:**
- Firestore Catalog, Shopping Cart, Order Management

### **Permissions:**
- Permission Handler, Custom Screens, Runtime Permissions

### **General:**
- BLoC Pattern, Responsive Design, Localization, Error Handling

---

## 🎯 ترتيب المذاكرة (من الأهم إلى الأقل أهمية)

1. **Medications** - الأكثر تعقيداً وتقنية
2. **Authentication** - أساس التطبيق
3. **Doctors & Appointments** - ميزة رئيسية
4. **Emergency System** - تقنيات متقدمة
5. **Profile Management** - مهم للمستخدم
6. **Permissions System** - مهم للنشر
7. **Health Exercises** - ميزة قيمة
8. **Grocery Shopping** - قيد التطوير
9. **الباقي** - مكملات

---

## 💡 نصائح للمذاكرة

1. **ابدأ بـ Medications**: فهم نظام المنبهات والـ Background tasks
2. **افهم BLoC Pattern**: كيف تعمل الـ Cubits والـ States
3. **راجع Firebase Structure**: كيف تنظم البيانات في Firestore
4. **تعرف على Services**: كيف تفصل المنطق عن UI
5. **شاهد الكود الحقيقي**: اقرأ الملفات الفعلية في المشروع

حظاً موفقاً في المذاكرة! 🚀

## 📚 ملفات مهمة يجب قراءتها لكل ميزة

### 1. **Medications (الأهم)**
```
1. lib/features/medications/viewmodel/medication_cubit.dart
2. lib/features/medications/model/medication_model.dart
3. lib/services/firestore/medication_service.dart
4. lib/services/firestore/alarm_service.dart
5. lib/services/firestore/persistent_alarm_service.dart
```

### 2. **Authentication**
```
1. lib/features/auth/viewmodel/auth_cubit.dart
2. lib/features/auth/model/user_model.dart
3. lib/services/auth/auth_service.dart
```

### 3. **Doctors**
```
1. lib/features/doctors/viewmodel/doctors_cubit.dart
2. lib/features/doctors/model/doctor_model.dart
3. lib/services/firestore/doctor_service.dart
```

### 4. **Emergency**
```
1. lib/features/emergency/viewmodel/emergency_contacts_cubit.dart
2. lib/services/location/location_service.dart
```

### 5. **Profile**
```
1. lib/features/profile/viewmodel/profile_cubit.dart
2. lib/services/firestore/user_service.dart
3. lib/services/supabase_storage_service.dart
```

### 6. **Permissions**
```
1. lib/features/permissions/utils/permission_helper.dart
```

### 7. **Health**
```
1. lib/features/health/model/exercise_model.dart
2. lib/features/health/viewmodel/health_cubit.dart
```

---

## 🎯 أسئلة تقنية متوقعة لكل ميزة

### **Medications:**
1. كيف تعمل المنبهات حتى مع إغلاق التطبيق؟
2. كيف تحسب نسبة الالتزام؟
3. كيف تتعامل مع المناطق الزمنية المختلفة؟
4. كيف تضمن إعادة جدولة المنبهات بعد إعادة تشغيل الجهاز؟

### **Authentication:**
1. كيف تتعامل مع حالات الخطأ المختلفة في التسجيل؟
2. كيف تخزن بيانات المستخدم بعد التسجيل؟
3. كيف تدعم تسجيل الدخول بـ Google و Facebook؟

### **Doctors:**
1. كيف تبحث في بيانات متعددة اللغات؟
2. كيف تنظم البيانات في Firestore؟
3. كيف تعمل نظام النقاط للأطباء؟

### **Emergency:**
1. كيف تحصل على الموقع في الخلفية؟
2. كيف تتعامل مع أذونات الموقع؟
3. كيف تضمن دقة الموقع؟

### **Profile:**
1. لماذا استخدمت Supabase بدلاً من Firebase Storage؟
2. كيف تضغط الصور قبل الرفع؟
3. كيف تدير cache الصور؟

### **Permissions:**
1. كيف تطلب الأذونات في runtime؟
2. كيف تتعامل مع المستخدمين الذين يرفضون الأذونات؟
3. كيف تشرح للمستخدم سبب الحاجة للإذن؟

### **Health:**
1. كيف تنظم بيانات التمارين متعددة اللغات؟
2. كيف تعرض تعليمات التمارين؟

---

## ⏱️ خطة المذاكرة (3 أيام)

### **اليوم الأول: الميزات الأساسية**
- Medications (3 ساعات)
- Authentication (2 ساعة)
- Profile (1 ساعة)

### **اليوم الثاني: الميزات المتوسطة**
- Doctors & Appointments (3 ساعات)
- Emergency System (2 ساعة)
- Permissions (1 ساعة)

### **اليوم الثالث: الميزات المتبقية**
- Health Exercises (2 ساعة)
- Grocery Shopping (1 ساعة)
- المراجعة العامة (3 ساعات)

---

## 💡 نصائح إضافية

1. **افتح الملفات واقرأ الكود**: لا تعتمد فقط على الملخص
2. **جرب تشغيل التطبيق**: فهم التطبيق عملياً
3. **اكتب ملاحظات**: دوّن النقاط المهمة
4. **تمرن على الشرح**: حاول شرح كل ميزة لنفسك
5. **راجع الأسئلة المتوقعة**: استعد للإجابة عليها

كل ميزة لها:
1. **Model**: هيكل البيانات
2. **View**: واجهة المستخدم
3. **ViewModel (Cubit)**: إدارة الحالة
4. **Service**: التعامل مع الخادم

افهم هذه الأجزاء الأربعة لكل ميزة وسوف تفهم المشروع بالكامل! 🎯