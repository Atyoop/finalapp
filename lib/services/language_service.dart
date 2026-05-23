import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service to manage and persist the selected app language.
class LanguageService {
  static const String _key = 'selected_language';
  static const Set<String> supportedLanguages = {'en', 'ar'};
  static String _currentLanguage = 'en';

  /// Returns the current selected language code ('en' or 'ar') synchronously.
  static String get currentLanguage => _currentLanguage;

  /// Returns true when the current selected language is Arabic.
  static bool get isArabic => _currentLanguage == 'ar';

  /// Query parameters containing the currently selected language.
  static Map<String, String> get languageQueryParameters => {
    'lang': _currentLanguage,
  };

  /// Appends the selected language to [uri] while preserving existing params.
  static Uri appendLanguageQuery(
    Uri uri, [
    Map<String, dynamic>? queryParameters,
  ]) {
    final merged = <String, String>{
      ...uri.queryParameters,
      if (queryParameters != null)
        ...queryParameters.map((key, value) => MapEntry(key, value.toString())),
      'lang': _currentLanguage,
    };
    return uri.replace(queryParameters: merged);
  }

  /// Initializes the service by reading the stored language from SharedPreferences.
  /// Call this in the main() function before running the app.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedLanguage = prefs.getString(_key);
      _currentLanguage = supportedLanguages.contains(storedLanguage)
          ? storedLanguage!
          : 'en';
    } catch (_) {
      _currentLanguage = 'en';
    }
  }

  /// Saves and sets the preferred language code.
  static Future<void> setLanguage(String langCode) async {
    if (!supportedLanguages.contains(langCode)) return;
    _currentLanguage = langCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, langCode);
    } catch (_) {}
  }
}
