import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Supabase Storage Service - بدون authentication
class SupabaseStorageService {
  // ⚠️ غيّر هذه القيم من Supabase Dashboard
  static const String _supabaseUrl = 'https://pljrxqzinvdcyxffablj.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsanJ4cXppbnZkY3l4ZmZhYmxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MjAwMjcsImV4cCI6MjA4Mjk5NjAyN30.d_3_rgPfSBhxQgHu3Ht8wuOQMBtLCKtd9DNBjFo3tgc';

  static const String _baseUrl =
      '$_supabaseUrl/storage/v1/object/public/images';

  // ============================================
  // Profile Images Upload
  // ============================================

  /// رفع صورة البروفايل باستخدام HTTP مباشرة
  static Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_$timestamp.jpg';
      final filePath = 'images_profile/$userId/$fileName';

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload URL
      final uploadUrl = '$_supabaseUrl/storage/v1/object/images/$filePath';

      // Make HTTP request
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'image/jpeg',
          'x-upsert': 'true', // Allow overwriting
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - return public URL with cache buster
        final publicUrl = '$_baseUrl/$filePath?t=$timestamp';
        return publicUrl;
      } else {
        // Error
        final error = jsonDecode(response.body);
        throw Exception('فشل رفع الصورة: ${error['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: $e');
    }
  }

  /// حذف صورة البروفايل
  static Future<void> deleteProfileImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final bucketIndex = pathSegments.indexOf('images');
      if (bucketIndex == -1) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete URL
      final deleteUrl = '$_supabaseUrl/storage/v1/object/images/$filePath';

      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      );

      if (response.statusCode != 200) {
        print('تحذير: فشل حذف الصورة - ${response.body}');
      }
    } catch (e) {
      print('تحذير: خطأ في حذف الصورة - $e');
    }
  }

  /// الحصول على رابط صورة البروفايل
  static String getProfileImageUrl(String filePath) {
    return '$_baseUrl/$filePath';
  }

  // ============================================
  // Doctor Images
  // ============================================

  static String getDoctorImage(String fileName) {
    return '$_baseUrl/doctors/$fileName';
  }

  static String getDoctorImageByName(String doctorNameEn) {
    final fileName = doctorNameEn
        .toLowerCase()
        .replaceAll('dr. ', 'dr_')
        .replaceAll(' ', '_');
    return '$_baseUrl/doctors/$fileName.png';
  }

  static String get doctorPlaceholder {
    return '$_baseUrl/doctors/placeholder.png';
  }

  // ============================================
  // Specialty Images
  // ============================================

  static String getSpecialtyImage(String fileName) {
    return '$_baseUrl/specialties/$fileName';
  }

  static String getSpecialtyImageByIcon(String icon) {
    final Map<String, String> iconToFile = {
      'dental': 'dentist.png',
      'cardio': 'cardio.png',
      'derma': 'derma.png',
      'general': 'general.png',
      'pediatric': 'pediatric.png',
      'ortho': 'ortho.png',
    };
    final fileName = iconToFile[icon] ?? 'general.png';
    return '$_baseUrl/specialties/$fileName';
  }

  // ============================================
  // Exercise Images
  // ============================================

  static String getExerciseImage(String fileName) {
    return '$_baseUrl/exercises/$fileName';
  }

  static String get stretchNeck => '$_baseUrl/exercises/stretch_neck.png';
  static String get stretchShoulder =>
      '$_baseUrl/exercises/stretch_shoulder.png';
  static String get stretchArm => '$_baseUrl/exercises/stretch_arm.png';
  static String get stretchBack => '$_baseUrl/exercises/stretch_back.png';
  static String get stretchBreath => '$_baseUrl/exercises/stretch_breath.png';

  // ============================================
  // Grocery Images ✅ NEW
  // ============================================

  /// صورة تصنيف البقالة
  static String getGroceryCategoryImage(String fileName) {
    return '$_baseUrl/grocery/categories/$fileName';
  }

  /// صورة منتج البقالة
  static String getGroceryProductImage(String fileName) {
    return '$_baseUrl/grocery/products/$fileName';
  }

  /// صورة placeholder للبقالة
  static String get groceryPlaceholder {
    return '$_baseUrl/grocery/placeholder.png';
  }

  /// رفع صورة منتج بقالة
  static Future<String> uploadGroceryProductImage({
    required String productId,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_$timestamp.png';
      final filePath = 'grocery/products/$fileName';

      final bytes = await imageFile.readAsBytes();
      final uploadUrl = '$_supabaseUrl/storage/v1/object/images/$filePath';

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'image/png',
          'x-upsert': 'true',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_baseUrl/$filePath';
      } else {
        final error = jsonDecode(response.body);
        throw Exception('فشل رفع الصورة: ${error['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: $e');
    }
  }

  /// رفع صورة تصنيف بقالة
  static Future<String> uploadGroceryCategoryImage({
    required String categoryId,
    required File imageFile,
  }) async {
    try {
      final fileName = '$categoryId.png';
      final filePath = 'grocery/categories/$fileName';

      final bytes = await imageFile.readAsBytes();
      final uploadUrl = '$_supabaseUrl/storage/v1/object/images/$filePath';

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'image/png',
          'x-upsert': 'true',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_baseUrl/$filePath';
      } else {
        final error = jsonDecode(response.body);
        throw Exception('فشل رفع الصورة: ${error['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: $e');
    }
  }

  // ============================================
  // Generic Upload Method (للاستخدام العام) ✅ NEW
  // ============================================

  /// رفع أي ملف إلى مجلد محدد
  static Future<String?> uploadFile(File file, String folder) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = 'file_$timestamp.$extension';
      final filePath = '$folder/$fileName';

      final bytes = await file.readAsBytes();
      final uploadUrl = '$_supabaseUrl/storage/v1/object/images/$filePath';

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'image/$extension',
          'x-upsert': 'true',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_baseUrl/$filePath?t=$timestamp';
      } else {
      // تجنب محاولة فك ترميز JSON إذا كان الرد غير JSON (مثل صفحة HTML للخطأ 500)
      // نعيد رسالة الخطأ كما هي لتسهيل الفهم
      throw Exception('فشل رفع الملف: ${response.body}');
    }
  } catch (e) {
    print('خطأ في رفع الملف: $e');
    return null;
  }
  }

  // ============================================
  // Helper Methods
  // ============================================

  static bool isValidUrl(String? url) {
    return url != null && url.isNotEmpty && url.startsWith('http');
  }
}
