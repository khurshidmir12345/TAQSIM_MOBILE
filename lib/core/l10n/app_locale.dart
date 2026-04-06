import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_locale_holder.dart';

enum AppLocale {
  uz(Locale('uz'), "O'zbekcha", 'Lotin'),
  uzCyrl(Locale('uz', 'CYRL'), 'Ўзбекча', 'Кирилл'),
  ru(Locale('ru'), 'Русский', ''),
  kk(Locale('kk'), 'Қазақша', ''),
  ky(Locale('ky'), 'Кыргызча', ''),
  tr(Locale('tr'), 'Türkçe', ''),
  tg(Locale('tg'), 'Тоҷикӣ', '');

  final Locale locale;
  final String label;
  final String script;
  const AppLocale(this.locale, this.label, this.script);

  String get displayName => script.isEmpty ? label : '$label ($script)';

  String get code {
    final l = locale;
    if (l.countryCode != null && l.countryCode!.isNotEmpty) {
      return '${l.languageCode}_${l.countryCode}';
    }
    return l.languageCode;
  }

  static AppLocale fromCode(String code) =>
      AppLocale.values.firstWhere((e) => e.code == code, orElse: () => uz);
}

const _prefKey = 'app_locale';

class LocaleNotifier extends AsyncNotifier<AppLocale> {
  @override
  Future<AppLocale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    final resolved = code != null ? AppLocale.fromCode(code) : AppLocale.uz;
    ApiLocaleHolder.setCode(resolved.code);
    return resolved;
  }

  Future<void> setLocale(AppLocale locale) async {
    ApiLocaleHolder.setCode(locale.code);
    state = AsyncData(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.code);
  }
}

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, AppLocale>(LocaleNotifier.new);
