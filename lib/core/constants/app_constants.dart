import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const String appName = 'TAQSEEM';

  static const String prodBaseUrl = 'https://api.taqseem.uz/api';
  static const String devBaseUrl = 'https://api.dev.taqseem.uz/api';

  static const String _prodBaseUrl = prodBaseUrl;
  static const String _devBaseUrl = devBaseUrl;

  /// Release build definessiz yig'ilganda dev API'ga ulansinmi.
  ///
  /// **App Store / Play Store'ga chiqadigan build'da doim `false`.** Aks holda
  /// do'kondagi ilova dev serverga ulanib qoladi — 2026-08-04 da aynan shu
  /// bo'lgan edi.
  ///
  /// Sinash uchun vaqtincha `true` qilingan bo'lsa, yuborishdan oldin qaytarish
  /// SHART. Tekshirish oson: `true` bo'lganda ilovada **DEV banneri** ko'rinadi.
  /// Banner ko'rinsa — do'konga yubormang.
  ///
  /// Dev build kerak bo'lsa buni o'zgartirmang — `--dart-define=APP_ENV=dev`
  /// (yoki `scripts/build-dev-apk.sh`) ishlating.
  static const bool defaultToDev = false;

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
