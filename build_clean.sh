#!/bin/bash

# Script to clean and build Flutter app for Google Play

echo "🧹 تنظيف المشروع..."
echo "🧹 Cleaning project..."

# حذف مجلدات البناء
flutter clean

# حذف مجلدات Android build
rm -rf android/build/
rm -rf android/app/build/
rm -rf android/.gradle/

echo ""
echo "📦 تحديث Dependencies..."
echo "📦 Updating dependencies..."

flutter pub get

echo ""
echo "🔨 بناء AAB للإنتاج..."
echo "🔨 Building release AAB..."

flutter build appbundle --release

echo ""
echo "✅ تم الانتهاء!"
echo "✅ Done!"
echo ""
echo "📍 موقع الملف:"
echo "📍 File location:"
echo "build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "🚀 الآن ارفع الملف على Google Play Console"
echo "🚀 Now upload the file to Google Play Console"
