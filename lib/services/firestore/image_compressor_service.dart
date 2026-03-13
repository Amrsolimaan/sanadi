import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image Compressor Service
/// لضغط الصور قبل رفعها للحفاظ على الجودة وتقليل الحجم
class ImageCompressorService {
  /// ضغط الصورة
  /// - maxWidth: أقصى عرض (افتراضي: 1024)
  /// - maxHeight: أقصى ارتفاع (افتراضي: 1024)
  /// - quality: جودة الصورة من 0-100 (افتراضي: 85)
  static Future<File?> compressImage({
    required File imageFile,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('فشل ضغط الصورة');
      }

      return File(result.path);
    } catch (e) {
      throw Exception('خطأ في ضغط الصورة: $e');
    }
  }

  /// الحصول على حجم الملف بالميجابايت
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// التحقق من حجم الصورة
  /// Returns: true إذا كانت الصورة أكبر من الحد الأقصى
  static bool isFileSizeExceeded(File file, {double maxSizeMB = 5.0}) {
    final sizeInMB = getFileSizeInMB(file);
    return sizeInMB > maxSizeMB;
  }
}
