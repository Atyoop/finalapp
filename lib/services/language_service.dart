import 'medicine_storage_service.dart';

/// Centralized service to manage and persist the selected app language.
class LanguageService {
  static const String _key = 'selected_language';
  static const Set<String> supportedLanguages = {'en', 'ar'};
  static String _currentLanguage = 'en';
  static bool _hasSelectedLanguage = false;

  /// Returns the current selected language code ('en' or 'ar') synchronously.
  static String get currentLanguage => _currentLanguage;

  /// Whether the user has explicitly chosen a language at least once.
  static bool get hasSelectedLanguage => _hasSelectedLanguage;

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

  /// Initializes the service by reading the stored language from Hive.
  /// Call this in the main() function before running the app.
  static Future<void> init() async {
    final storedLanguage = MedicineStorageService.getSetting<String>(_key);
    _hasSelectedLanguage = supportedLanguages.contains(storedLanguage);
    _currentLanguage = storedLanguage ?? 'en';
    if (!supportedLanguages.contains(_currentLanguage)) {
      _currentLanguage = 'en';
    }
  }

  /// Saves and sets the preferred language code.
  static Future<void> setLanguage(String langCode) async {
    if (!supportedLanguages.contains(langCode)) return;
    _currentLanguage = langCode;
    await MedicineStorageService.saveSetting(_key, langCode);
    _hasSelectedLanguage = true;
  }
}
