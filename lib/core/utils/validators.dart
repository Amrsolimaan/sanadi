class Validators {
  Validators._();

  // Validate Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.required_field';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'validation.invalid_email';
    }
    return null;
  }

  // Validate Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.required_field';
    }
    if (value.length < 8) {
      return 'validation.password_too_short';
    }
    return null;
  }

  // Validate Confirm Password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'validation.required_field';
    }
    if (value != password) {
      return 'validation.passwords_dont_match';
    }
    return null;
  }

  // Validate Phone (Egyptian format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.required_field';
    }

    // Remove any spaces or dashes
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Check if it's a valid Egyptian number
    // Accepts: 01xxxxxxxxx or +201xxxxxxxxx
    final egyptianRegex = RegExp(r'^(\+20|0)?1[0-9]{9}$');
    if (!egyptianRegex.hasMatch(cleanedValue)) {
      return 'validation.invalid_phone';
    }
    return null;
  }

  // Format phone to E.164 (for Firebase)
  static String formatPhoneToE164(String phone) {
    // إزالة أي مسافات أو رموز (ماعدا + والأرقام)
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // إذا كان يبدأ بـ 0، استبدله بـ +20
    if (cleaned.startsWith('0')) {
      return '+2$cleaned'; // يحول 01008864664 إلى +201008864664
    }

    // إذا كان يبدأ بـ 1 فقط (بدون 0)، أضف +20
    if (cleaned.startsWith('1') && cleaned.length == 10) {
      return '+20$cleaned'; // يحول 1008864664 إلى +201008864664
    }

    // إذا كان يبدأ بـ 20، أضف + فقط
    if (cleaned.startsWith('20')) {
      return '+$cleaned';
    }

    // إذا كان مكتمل بالفعل
    if (cleaned.startsWith('+20')) {
      return cleaned;
    }

    // في حالة أي شكل آخر، افترض أنه يحتاج +20
    return '+20$cleaned';
  }

  // Validate Name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.required_field';
    }
    if (value.length < 2) {
      return 'validation.invalid_name';
    }
    return null;
  }

  // Validate OTP
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.required_field';
    }
    if (value.length != 4) {
      return 'validation.invalid_otp';
    }
    return null;
  }
}
