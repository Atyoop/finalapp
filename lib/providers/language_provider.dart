import 'package:flutter/material.dart';
import '../services/language_service.dart';

/// Centralized state provider for language switching.
class LanguageProvider extends ChangeNotifier {
  /// Returns the current selected language code ('en' or 'ar').
  String get currentLanguage => LanguageService.currentLanguage;

  /// Returns true if the selected language is Arabic.
  bool get isArabic => currentLanguage == 'ar';

  /// Direction used by the app shell and screens that need an explicit value.
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// Updates the preferred app language and notifies listeners to trigger UI rebuilds.
  Future<void> setLanguage(String langCode) async {
    if (!LanguageService.supportedLanguages.contains(langCode)) return;
    final didChange = LanguageService.currentLanguage != langCode;
    await LanguageService.setLanguage(langCode);
    if (didChange) notifyListeners();
  }
}
