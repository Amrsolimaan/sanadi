import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final int batteryLevel;
  final DateTime timestamp;
  final String? address; // ✅ إضافة العنوان

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.batteryLevel,
    required this.timestamp,
    this.address,
  });

  // تحويل دقة GPS لنص
  String get accuracyText {
    if (accuracy <= 5) return 'High (${accuracy.toInt()}m)';
    if (accuracy <= 20) return 'Medium (${accuracy.toInt()}m)';
    return 'Low (${accuracy.toInt()}m)';
  }

  // لون الدقة
  String get accuracyLevel {
    if (accuracy <= 5) return 'high';
    if (accuracy <= 20) return 'medium';
    return 'low';
  }

  // رابط Google Maps
  String get googleMapsUrl {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  // وقت التحديث
  String get formattedTime {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }
}

class LocationService {
  final Battery _battery = Battery();

  // التحقق من تفعيل خدمة الموقع
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // التحقق من الإذن
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // طلب الإذن
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // فتح إعدادات الموقع
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // الحصول على الموقع الحالي - محدّث بمعالجة أفضل
  Future<Position?> getCurrentPosition() async {
    try {
      // تحقق من تفعيل الخدمة
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location service is disabled');
        return null;
      }

      // تحقق من الإذن
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        print('⚠️ Location permission denied, requesting...');
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied after request');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied forever');
        return null;
      }

      print('✅ Getting current position...');

      // احصل على الموقع - مع timeout أطول ودقة متوسطة أولاً
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
        );
        print(
            '✅ Position obtained: ${position.latitude}, ${position.longitude}');
        return position;
      } catch (e) {
        print('⚠️ High accuracy failed, trying medium: $e');
        // إذا فشل High accuracy، جرب Medium
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 30),
          );
          print(
              '✅ Position obtained (medium): ${position.latitude}, ${position.longitude}');
          return position;
        } catch (e2) {
          print('⚠️ Medium accuracy failed, trying low: $e2');
          // آخر محاولة بـ Low accuracy
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 30),
          );
          print(
              '✅ Position obtained (low): ${position.latitude}, ${position.longitude}');
          return position;
        }
      }
    } catch (e) {
      print('❌ Error getting position: $e');
      return null;
    }
  }

  // الحصول على مستوى البطارية
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      print('⚠️ Error getting battery level: $e');
      return -1;
    }
  }

  // جمع كل البيانات
  Future<LocationData?> getLocationData() async {
    print('📍 Starting to get location data...');

    final position = await getCurrentPosition();
    if (position == null) {
      print('❌ Failed to get position');
      return null;
    }

    final batteryLevel = await getBatteryLevel();
    print('🔋 Battery level: $batteryLevel%');

    // ✅ جلب العنوان من الإحداثيات
    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    print('📍 Address: ${address ?? "Unknown"}');

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      batteryLevel: batteryLevel,
      timestamp: DateTime.now(),
      address: address,
    );
  }

  // ✅ تحويل الإحداثيات إلى عنوان (Reverse Geocoding)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // الطريقة الأولى: Google Geocoding API (أفضل للعربي)
      const String apiKey = 'AIzaSyAsvAxjNyNXhoLrjmYDE0jTrWgr6kgpmW8';
      
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng'
          '&key=$apiKey'
          '&language=ar'
          '&result_type=street_address|route|neighborhood|locality';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }

      // الطريقة الثانية: مكتبة geocoding (Fallback)
      print('⚠️ Google API failed, trying geocoding package...');
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((p) => p != null && p.isNotEmpty).join('، ');
      }
    } catch (e) {
      print('❌ Error getting address: $e');
    }
    return null;
  }

  // إنشاء رسالة WhatsApp
  String createWhatsAppMessage({
    required String senderName,
    required LocationData locationData,
    required String language,
  }) {
    if (language == 'ar') {
      return '''
🆘 تنبيه من تطبيق سنادي

👤 المرسل: $senderName

📍 الموقع الحالي:
${locationData.googleMapsUrl}

📡 دقة الموقع: ${locationData.accuracyText}
🔋 البطارية: ${locationData.batteryLevel}%
⏰ الوقت: ${locationData.formattedTime}

━━━━━━━━━━━━━━━━━━━━
هذه الرسالة مرسلة تلقائياً من تطبيق سنادي لرعاية كبار السن
      ''';
    }

    return '''
🆘 Alert from Sanadi App

👤 Sender: $senderName

📍 Current Location:
${locationData.googleMapsUrl}

📡 GPS Accuracy: ${locationData.accuracyText}
🔋 Battery: ${locationData.batteryLevel}%
⏰ Time: ${locationData.formattedTime}

━━━━━━━━━━━━━━━━━━━━
This message was sent automatically from Sanadi - Elder Care App
    ''';
  }

  // إرسال عبر WhatsApp لشخص محدد
  Future<bool> sendViaWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // تنظيف الرقم
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+$cleanPhone';
      }

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error sending WhatsApp: $e');
      return false;
    }
  }

  // مشاركة مع الجميع (Share Sheet)
  Future<void> shareWithAll({
    required String message,
  }) async {
    await Share.share(
      message,
      subject: 'Location from Sanadi App',
    );
  }
}
