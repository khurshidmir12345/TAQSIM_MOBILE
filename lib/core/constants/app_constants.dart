import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const String appName = 'TAQSEEM';

  /// Obuna/billing UI'ni umumiy yoqish/o'chirish kaliti.
  /// false bo'lsa: obuna, balans/hamyon va tariflar ekranlari yashiriladi
  /// (ilova bepul ishlaydi). Kod saqlanadi — true qilinsa hammasi tiklanadi.
  /// Backenddagi `BILLING_ENABLED` bilan birga o'zgartirilishi kerak.
  static const bool billingEnabled = false;

  static const String _prodBaseUrl = 'https://api.taqseem.uz/api';
  static const String _devBaseUrl = 'https://api.dev.taqseem.uz/api';

  // Aniq override (ixtiyoriy): flutter run --dart-define=API_BASE_URL=...
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Debug/profile build (`flutter run`) → dev server.
  /// Release build (`flutter build --release`) → production server.
  /// Kerak bo'lsa `--dart-define=API_BASE_URL=...` bilan majburan o'zgartiriladi.
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
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
