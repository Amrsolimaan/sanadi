class SupabaseStorage {
  // Base URL for Supabase Storage
  static const String _baseUrl = 
      'https://pljrxqzinvdcyxffablj.supabase.co/storage/v1/object/public/images';

  // ============================================
  // Doctor Images
  // ============================================
  
  /// Get doctor image URL by filename
  static String getDoctorImage(String filename) {
    return '$_baseUrl/doctors/$filename';
  }

  /// Get doctor image URL by doctor name (English)
  static String getDoctorImageByName(String name) {
    // Convert name to filename format
    // "Dr. Andrew" -> "dr_andrew.png"
    final filename = name
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(' ', '_')
        .trim();
    return '$_baseUrl/doctors/$filename.png';
  }

  /// Placeholder for doctors without image
  static String get doctorPlaceholder => '$_baseUrl/doctors/placeholder.png';

  // ============================================
  // Specialty Images
  // ============================================
  
  /// Get specialty image URL by filename
  static String getSpecialtyImage(String filename) {
    return '$_baseUrl/specialties/$filename';
  }

  /// Get specialty image by icon name
  static String getSpecialtyImageByIcon(String icon) {
    final iconMap = {
      'heart': 'cardiology.png',
      'brain': 'neurology.png',
      'bone': 'orthopedics.png',
      'tooth': 'dental.png',
      'eye': 'ophthalmology.png',
      'child': 'pediatrics.png',
      'general': 'general.png',
    };
    final filename = iconMap[icon] ?? 'general.png';
    return '$_baseUrl/specialties/$filename';
  }

  // ============================================
  // Exercise Images
  // ============================================
  
  /// Get exercise image URL by filename
  static String getExerciseImage(String filename) {
    return '$_baseUrl/exercises/$filename';
  }

  /// Static exercise image URLs
  static String get stretchNeck => '$_baseUrl/exercises/stretch_neck.png';
  static String get stretchShoulder => '$_baseUrl/exercises/stretch_shoulder.png';
  static String get stretchArm => '$_baseUrl/exercises/stretch_arm.png';
  static String get stretchBack => '$_baseUrl/exercises/stretch_back.png';
  static String get stretchBreath => '$_baseUrl/exercises/stretch_breath.png';
}
