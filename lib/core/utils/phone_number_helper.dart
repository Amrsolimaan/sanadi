// phone_number_helper.dart
// أنشئ هذا الملف في مجلد utils أو helpers

class PhoneNumberHelper {
  /// معالجة رقم الهاتف المصري وإضافة رمز الدولة تلقائياً
  ///
  /// أمثلة:
  /// - "01008864664" => "+201008864664"
  /// - "1008864664" => "+201008864664"
  /// - "+201008864664" => "+201008864664"
  /// - "00201008864664" => "+201008864664"
  /// - "201008864664" => "+201008864664"
  static String formatEgyptianPhone(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return phoneNumber;
    }

    // إزالة أي مسافات أو شرطات أو أقواس
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // حالة 1: الرقم يبدأ بـ +20
    if (cleaned.startsWith('+20')) {
      return cleaned;
    }

    // حالة 2: الرقم يبدأ بـ 0020
    if (cleaned.startsWith('0020')) {
      return '+${cleaned.substring(2)}'; // إزالة 00 والاحتفاظ بـ 20
    }

    // حالة 3: الرقم يبدأ بـ 20
    if (cleaned.startsWith('20') && cleaned.length >= 12) {
      return '+$cleaned';
    }

    // حالة 4: الرقم يبدأ بـ 0 (رقم محلي مصري)
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '+20${cleaned.substring(1)}'; // إزالة الصفر وإضافة +20
    }

    // حالة 5: الرقم بدون صفر في البداية (10 أرقام)
    if (cleaned.length == 10 && !cleaned.startsWith('0')) {
      return '+20$cleaned';
    }

    // إذا لم يتطابق مع أي حالة، نفترض أنه رقم محلي بدون صفر
    if (cleaned.length >= 10) {
      // إذا كان يبدأ بـ 1 (بداية الأرقام المحلية المصرية)
      if (cleaned.startsWith('1')) {
        return '+20$cleaned';
      }
    }

    // في حالة عدم التطابق مع أي نمط، نعيد الرقم كما هو
    return phoneNumber;
  }

  /// التحقق من صحة رقم الهاتف المصري
  /// يجب أن يكون الرقم 11 رقم أو 10 بعد إزالة الصفر
  static bool isValidEgyptianPhone(String phoneNumber) {
    String formatted = formatEgyptianPhone(phoneNumber);

    // الرقم المصري الصحيح يجب أن يكون +20 متبوعاً بـ 10 أرقام
    RegExp egyptPattern = RegExp(r'^\+20(1[0-5]|10|11|12|15)\d{8}$');

    return egyptPattern.hasMatch(formatted);
  }

  /// الحصول على الرقم بدون رمز الدولة للعرض
  static String getDisplayNumber(String phoneNumber) {
    String formatted = formatEgyptianPhone(phoneNumber);

    if (formatted.startsWith('+20')) {
      return '0${formatted.substring(3)}'; // إرجاع الرقم بصيغة 01xxxxxxxxx
    }

    return phoneNumber;
  }

  /// الحصول على رمز الدولة من الرقم
  static String getCountryCode(String phoneNumber) {
    String formatted = formatEgyptianPhone(phoneNumber);

    if (formatted.startsWith('+')) {
      // استخراج رمز الدولة (الأرقام بعد + حتى أول رقم محلي)
      RegExp codePattern = RegExp(r'^\+(\d{1,3})');
      Match? match = codePattern.firstMatch(formatted);

      if (match != null) {
        return match.group(1) ?? '';
      }
    }

    return '20'; // افتراضي مصر
  }
}

// ======= مثال على الاستخدام =======

void main() {
  // اختبار التنسيق
  print(PhoneNumberHelper.formatEgyptianPhone('01008864664'));
  // Output: +201008864664

  print(PhoneNumberHelper.formatEgyptianPhone('1008864664'));
  // Output: +201008864664

  print(PhoneNumberHelper.formatEgyptianPhone('+201008864664'));
  // Output: +201008864664

  print(PhoneNumberHelper.formatEgyptianPhone('00201008864664'));
  // Output: +201008864664

  print(PhoneNumberHelper.formatEgyptianPhone('201008864664'));
  // Output: +201008864664

  // اختبار التحقق
  print(PhoneNumberHelper.isValidEgyptianPhone('01008864664'));
  // Output: true

  print(PhoneNumberHelper.isValidEgyptianPhone('0123456789'));
  // Output: false

  // الحصول على رقم العرض
  print(PhoneNumberHelper.getDisplayNumber('+201008864664'));
  // Output: 01008864664
}
