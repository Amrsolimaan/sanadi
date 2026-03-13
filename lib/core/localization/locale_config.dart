import 'package:flutter/material.dart';

class LocaleConfig {
  LocaleConfig._();

  static const String translationsPath = 'assets/translations';

  static const Locale englishLocale = Locale('en');
  static const Locale arabicLocale = Locale('ar');

  static const List<Locale> supportedLocales = [englishLocale, arabicLocale];

  static const Locale fallbackLocale = englishLocale;
}
