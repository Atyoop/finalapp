import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String t(String key, [Map<String, Object?> args = const {}]) {
    var value = _strings[key] ?? key;
    args.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement?.toString() ?? '');
    });
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = locale.languageCode == 'ar' ? 'ar' : 'en';
    final jsonString = await rootBundle.loadString(
      'lib/l10n/app_$languageCode.arb',
    );
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    final strings = <String, String>{};
    jsonMap.forEach((key, value) {
      if (!key.startsWith('@') && value is String) {
        strings[key] = value;
      }
    });
    return AppLocalizations(Locale(languageCode), strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
