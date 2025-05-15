import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', ''); // Default to English

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  void toggleLocale() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('ar', ''));
    } else {
      setLocale(const Locale('en', ''));
    }
  }
}
