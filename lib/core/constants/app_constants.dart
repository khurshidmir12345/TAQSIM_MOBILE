import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const String appName = 'TAQSEEM';

  static const String prodBaseUrl = 'https://api.taqseem.uz/api';
  static const String devBaseUrl = 'https://api.dev.taqseem.uz/api';

  static const String _prodBaseUrl = prodBaseUrl;
  static const String _devBaseUrl = devBaseUrl;

  /// Release build definessiz yig'ilganda dev API'ga ulansinmi.
  ///
  /// Hozir `true`: `flutter build apk` ni definessiz ishlatganda ham dev
  /// serverga ulanadi — qo'lda sinash uchun shunday qulay.
  ///
  /// ⚠️ **App Store / Play Store'ga build yuborishdan OLDIN `false` qiling.**
  /// Aks holda do'kondagi ilova dev serverga ulanib qoladi — 2026-08-04 da
  /// aynan shu bo'lgan edi.
  ///
  /// Tekshirish oson: `true` bo'lganda ilovada **DEV banneri** ko'rinadi.
  /// Banner ko'rinsa — do'konga yubormang.
  ///
  /// Prod build kerak bo'lsa bu bayroqqa tegmasdan ham olish mumkin:
  /// `scripts/build-prod-apk.sh` (yoki `--dart-define=APP_ENV=prod`) —
  /// aniq define bayroqdan doim ustun turadi.
  static const bool defaultToDev = true;

  // Aniq override (ixtiyoriy): flutter run --dart-define=API_BASE_URL=...
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Compile-time env: `--dart-define=APP_ENV=dev|prod` (see config/*.json).
  static const String _appEnv = String.fromEnvironment('APP_ENV');

  /// Definessiz: [defaultToDev] `true` bo'lgani uchun **hamma rejimda dev**.
  /// `false` ga qaytarilsa: release → prod, debug/profile → dev.
  /// Defines bilan: [APP_ENV] yoki [API_BASE_URL] aniq ustun turadi.
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (_appEnv == 'dev') return _devBaseUrl;
    if (_appEnv == 'prod') return _prodBaseUrl;
    return defaultToDev || !kReleaseMode ? _devBaseUrl : _prodBaseUrl;
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
