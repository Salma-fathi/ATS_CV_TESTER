import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en', '');
  
  Locale get currentLocale => _currentLocale;
  bool get isArabic => _currentLocale.languageCode == 'ar';
  
  void setLocale(Locale locale) {
    if (locale.languageCode != _currentLocale.languageCode) {
      _currentLocale = locale;
      notifyListeners();
    }
  }
  
  void toggleLanguage() {
    if (_currentLocale.languageCode == 'en') {
      setLocale(const Locale('ar', ''));
    } else {
      setLocale(const Locale('en', ''));
    }
  }
  
  // Set language based on detected content
  void setLanguageBasedOnContent(String content) {
    // Simple detection - if content contains more Arabic characters than Latin
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    final latinRegex = RegExp(r'[a-zA-Z]');
    
    final arabicMatches = arabicRegex.allMatches(content).length;
    final latinMatches = latinRegex.allMatches(content).length;
    
    if (arabicMatches > latinMatches) {
      setLocale(const Locale('ar', ''));
    } else {
      setLocale(const Locale('en', ''));
    }
  }
}