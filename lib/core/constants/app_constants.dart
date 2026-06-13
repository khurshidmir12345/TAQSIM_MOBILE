import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const String appName = 'TAQSEEM';

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
}
