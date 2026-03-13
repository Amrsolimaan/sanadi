class SocialImageHelper {
  /// ✅ الحصول على صورة Google بجودة عالية
  static String getHighQualityGooglePhoto(String photoUrl) {
    if (photoUrl.contains('googleusercontent.com')) {
      // إزالة المعاملات القديمة وإضافة حجم كبير
      final baseUrl = photoUrl.split('=')[0];
      return '$baseUrl=s500'; // s500 = 500x500 pixels
    }
    return photoUrl;
  }

  /// ✅ الحصول على صورة Facebook بجودة عالية
  static String getHighQualityFacebookPhoto(String photoUrl) {
    if (photoUrl.contains('facebook.com') || photoUrl.contains('fbcdn.net')) {
      // استبدال الحجم الصغير بحجم كبير
      return photoUrl
          .replaceAll('type=small', 'type=large')
          .replaceAll('type=normal', 'type=large')
          .replaceAll('width=50', 'width=500')
          .replaceAll('height=50', 'height=500');
    }
    return photoUrl;
  }

  /// ✅ تحسين جودة الصورة حسب المصدر
  static String getHighQualityPhoto(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';
    
    if (photoUrl.contains('googleusercontent.com')) {
      return getHighQualityGooglePhoto(photoUrl);
    } else if (photoUrl.contains('facebook.com') || photoUrl.contains('fbcdn.net')) {
      return getHighQualityFacebookPhoto(photoUrl);
    }
    
    return photoUrl;
  }
}