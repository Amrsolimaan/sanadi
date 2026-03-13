# إصلاح مشكلة صلاحيات الصور والفيديو
## Photo and Video Permissions Fix

### المشكلة / Problem
تم رفض التطبيق من Google Play بسبب الاستخدام غير الصحيح لصلاحيات `READ_MEDIA_IMAGES` و `READ_MEDIA_VIDEO`.

The app was rejected by Google Play due to invalid use of `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO` permissions.

### السبب / Root Cause
التطبيق كان يطلب صلاحيات دائمة للوصول للصور والفيديوهات، بينما الاستخدام الفعلي يحتاج فقط وصول لمرة واحدة (لتغيير صورة البروفايل وإضافة صور المنتجات).

The app was requesting persistent access to photos and videos, while the actual use case only requires one-time access (for profile picture changes and product images).

### الحل / Solution

#### 1. إزالة صلاحية READ_MEDIA_IMAGES من AndroidManifest.xml
تم حذف السطر التالي:
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

#### 2. الاعتماد على Photo Picker API
- على Android 13+ (API 33+)، مكتبة `image_picker` تستخدم تلقائياً Photo Picker API
- هذا الـ API لا يحتاج صلاحيات manifest
- يعطي المستخدم تحكم كامل في اختيار الصور بدون منح صلاحيات دائمة

On Android 13+ (API 33+), the `image_picker` library automatically uses the Photo Picker API which:
- Doesn't require manifest permissions
- Gives users full control over photo selection
- Doesn't grant persistent access to the photo library

#### 3. الصلاحيات المتبقية / Remaining Permissions
```xml
<!-- For Android 12 and below only -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
```

هذه الصلاحية محدودة فقط لـ Android 12 وأقل، ولن تؤثر على Android 13+.

This permission is limited to Android 12 and below only, and won't affect Android 13+.

### الاستخدام الفعلي في التطبيق / Actual Usage in App

1. **تغيير صورة البروفايل** - Profile Picture Change
   - المستخدم يختار صورة واحدة من المعرض
   - لا يحتاج وصول دائم للمعرض

2. **إضافة صور المنتجات (لوحة الإدارة)** - Product Images (Admin Panel)
   - المسؤول يختار صورة واحدة لكل منتج
   - لا يحتاج وصول دائم للمعرض

### التأكد من الإصلاح / Verification

✅ تم حذف `READ_MEDIA_IMAGES` من AndroidManifest.xml
✅ تم حذف الكود غير المستخدم لطلب صلاحية الصور
✅ `image_picker` يستخدم Photo Picker API تلقائياً على Android 13+
✅ الصلاحيات المتبقية محدودة بـ `maxSdkVersion="32"`

### الرد على Google Play / Response to Google Play

**English:**
We have removed the `READ_MEDIA_IMAGES` permission from our AndroidManifest.xml. Our app now uses the Photo Picker API (available on Android 13+) which doesn't require manifest permissions and provides users with granular control over photo selection.

For Android 12 and below, we only request `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"`.

Our use case is limited to:
1. One-time profile picture selection by users
2. One-time product image selection by administrators

Both use cases are handled by `image_picker` library which automatically uses the appropriate API based on the Android version.

**Arabic:**
قمنا بإزالة صلاحية `READ_MEDIA_IMAGES` من ملف AndroidManifest.xml. التطبيق الآن يستخدم Photo Picker API (المتوفر على Android 13+) والذي لا يحتاج صلاحيات manifest ويعطي المستخدمين تحكم دقيق في اختيار الصور.

بالنسبة لـ Android 12 وأقل، نطلب فقط `READ_EXTERNAL_STORAGE` مع `maxSdkVersion="32"`.

حالات الاستخدام محدودة في:
1. اختيار صورة البروفايل لمرة واحدة من قبل المستخدمين
2. اختيار صور المنتجات لمرة واحدة من قبل المسؤولين

كلا الحالتين يتم التعامل معهما عبر مكتبة `image_picker` التي تستخدم تلقائياً الـ API المناسب حسب إصدار Android.
