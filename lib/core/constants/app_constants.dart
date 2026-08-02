import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const String appName = 'TAQSEEM';

  static const String prodBaseUrl = 'https://api.taqseem.uz/api';
  static const String devBaseUrl = 'https://api.dev.taqseem.uz/api';

  static const String _prodBaseUrl = prodBaseUrl;
  static const String _devBaseUrl = devBaseUrl;

  // Aniq override (ixtiyoriy): flutter run --dart-define=API_BASE_URL=...
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Compile-time env: `--dart-define=APP_ENV=dev|prod` (see config/*.json).
  static const String _appEnv = String.fromEnvironment('APP_ENV');

  /// Default (no defines): debug/profile → dev, release → production.
  /// With defines: [APP_ENV] or [API_BASE_URL] override explicitly.
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (_appEnv == 'dev') return _devBaseUrl;
    if (_appEnv == 'prod') return _prodBaseUrl;
    return kReleaseMode ? _prodBaseUrl : _devBaseUrl;
  }

  // ─── Google Sign-In ──────────────────────────────────────────────────────
  /// Web (server) OAuth client ID. Android'da `serverClientId` sifatida
  /// majburiy; backend ID token `aud` ni shu qiymatga tekshiradi.
  static const String googleServerClientId =
      '668168366908-61n4be971j9scsvc6mepaba1g2e73o1f.apps.googleusercontent.com';

  /// iOS OAuth client ID (GoogleService-Info.plist `CLIENT_ID`).
  static const String googleIosClientId =
      '668168366908-kpclm2r1vmbt0r4kl2s9eb5srb7n4r6p.apps.googleusercontent.com';
}
