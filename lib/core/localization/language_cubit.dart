import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final Locale locale;
  final int rebuildKey; // Force rebuild

  LanguageState({
    required this.locale,
    required this.rebuildKey,
  });

  LanguageState copyWith({Locale? locale, int? rebuildKey}) {
    return LanguageState(
      locale: locale ?? this.locale,
      rebuildKey: rebuildKey ?? this.rebuildKey,
    );
  }
}

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit()
      : super(LanguageState(locale: const Locale('en'), rebuildKey: 0));

  static const String _languageKey = 'selected_language';

  // ✅ Load saved language or use device language
  Future<void> loadSavedLanguage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey);

    Locale locale;

    if (savedLanguageCode != null) {
      // ✅ إذا كان المستخدم قد اختار لغة من قبل، استخدمها
      locale = Locale(savedLanguageCode);
    } else {
      // ✅ إذا لم يختر، استخدم لغة الجهاز (context.deviceLocale)
      locale = context.deviceLocale;

      // ✅ تأكد أن لغة الجهاز مدعومة، وإلا استخدم الإنجليزية
      final supportedLanguages = ['en', 'ar'];
      if (!supportedLanguages.contains(locale.languageCode)) {
        locale = const Locale('en');
      }
    }

    if (context.mounted) {
      await context.setLocale(locale);
    }

    emit(LanguageState(locale: locale, rebuildKey: state.rebuildKey));
  }

  // ✅ Change language and save preference
  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    final locale = Locale(languageCode);

    // Set locale in easy_localization
    if (context.mounted) {
      await context.setLocale(locale);
    }

    // Emit new state with incremented rebuildKey to force rebuild
    emit(LanguageState(
      locale: locale,
      rebuildKey: state.rebuildKey + 1,
    ));
  }

  // Toggle between Arabic and English
  Future<void> toggleLanguage(BuildContext context) async {
    final newLang = state.locale.languageCode == 'ar' ? 'en' : 'ar';
    await changeLanguage(context, newLang);
  }

  bool get isArabic => state.locale.languageCode == 'ar';
  bool get isEnglish => state.locale.languageCode == 'en';
}
