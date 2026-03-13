/// Supabase Storage Helper
/// URLs للصور المخزنة في Supabase Storage
class SupabaseStorage {
  // Base URL للصور
  static const String _baseUrl =
      'https://pljrxqzinvdcyxffablj.supabase.co/storage/v1/object/public/images';

  // ===== صور الأطباء =====
  static String getDoctorImage(String fileName) {
    return '$_baseUrl/doctors/$fileName';
  }

  /// الحصول على صورة الطبيب من اسمه الإنجليزي
  /// مثال: "Dr. Andrew" → "dr_andrew.png"
  static String getDoctorImageByName(String doctorNameEn) {
    final fileName = doctorNameEn
        .toLowerCase()
        .replaceAll('dr. ', 'dr_')
        .replaceAll(' ', '_');
    return '$_baseUrl/doctors/$fileName.png';
  }

  /// Placeholder للطبيب إذا لم توجد صورة
  static String get doctorPlaceholder {
    return '$_baseUrl/doctors/placeholder.png';
  }

  // ===== صور التخصصات =====
  static String getSpecialtyImage(String fileName) {
    return '$_baseUrl/specialties/$fileName';
  }

  /// الحصول على صورة التخصص من الأيقونة
  /// مثال: "dental" → "dentist.png"
  static String getSpecialtyImageByIcon(String icon) {
    // تحويل اسم الأيقونة لاسم الملف
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

  // ===== صور التمارين =====
  static String getExerciseImage(String fileName) {
    return '$_baseUrl/exercises/$fileName';
  }

  /// صور التمارين الثابتة
  static String get stretchNeck => '$_baseUrl/exercises/stretch_neck.png';
  static String get stretchShoulder => '$_baseUrl/exercises/stretch_shoulder.png';
  static String get stretchArm => '$_baseUrl/exercises/stretch_arm.png';
  static String get stretchBack => '$_baseUrl/exercises/stretch_back.png';
  static String get stretchBreath => '$_baseUrl/exercises/stretch_breath.png';

  // ===== Helper Methods =====
  
  /// التحقق من وجود الصورة (للاستخدام مع errorBuilder)
  static bool isValidUrl(String? url) {
    return url != null && url.isNotEmpty && url.startsWith('http');
  }
}
