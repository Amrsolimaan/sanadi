@echo off
REM Script to clean and build Flutter app for Google Play (Windows)

echo.
echo ====================================
echo تنظيف وبناء التطبيق
echo Clean and Build App
echo ====================================
echo.

echo 🧹 تنظيف المشروع...
echo 🧹 Cleaning project...
echo.

call flutter clean

if exist "android\build" rmdir /s /q "android\build"
if exist "android\app\build" rmdir /s /q "android\app\build"
if exist "android\.gradle" rmdir /s /q "android\.gradle"

echo.
echo 📦 تحديث Dependencies...
echo 📦 Updating dependencies...
echo.

call flutter pub get

echo.
echo 🔨 بناء AAB للإنتاج...
echo 🔨 Building release AAB...
echo.

call flutter build appbundle --release

echo.
echo ====================================
echo ✅ تم الانتهاء!
echo ✅ Done!
echo ====================================
echo.
echo 📍 موقع الملف:
echo 📍 File location:
echo build\app\outputs\bundle\release\app-release.aab
echo.
echo 🚀 الآن ارفع الملف على Google Play Console
echo 🚀 Now upload the file to Google Play Console
echo.
pause
