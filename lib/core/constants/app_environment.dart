import 'package:flutter/foundation.dart';

import 'app_constants.dart';

/// Compile-time environment (`APP_ENV`, `API_BASE_URL` from `--dart-define-from-file`).
abstract final class AppEnvironment {
  static const String rawAppEnv = String.fromEnvironment('APP_ENV');
  static const String rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool _configurationChecked = false;

  /// Throws [StateError] when dev/prod signals conflict (fail-fast, all modes).
  static void ensureValidConfiguration() {
    if (_configurationChecked) return;
    _configurationChecked = true;

    final error = configurationError(
      appEnv: rawAppEnv,
      apiBaseUrl: rawApiBaseUrl,
    );
    if (error != null) {
      throw StateError(error);
    }
  }

  /// Returns a human-readable error when [appEnv] and [apiBaseUrl] disagree.
  @visibleForTesting
  static String? configurationError({
    required String appEnv,
    required String apiBaseUrl,
  }) {
    if (appEnv.isNotEmpty && appEnv != 'dev' && appEnv != 'prod') {
      return 'Invalid APP_ENV "$appEnv". Expected "dev" or "prod".';
    }

    if (appEnv.isEmpty || apiBaseUrl.isEmpty) {
      return null;
    }

    final envIsDev = appEnv == 'dev';
    final pointsToDev = apiBaseUrl == AppConstants.devBaseUrl;
    final pointsToProd = apiBaseUrl == AppConstants.prodBaseUrl;

    if (envIsDev && pointsToProd) {
      return 'Conflicting build config: APP_ENV=dev with production API_BASE_URL.';
    }
    if (!envIsDev && pointsToDev) {
      return 'Conflicting build config: APP_ENV=prod with development API_BASE_URL.';
    }

    return null;
  }

  @visibleForTesting
  static bool resolveIsDev({
    required String appEnv,
    required String apiBaseUrl,
    required bool releaseMode,
  }) {
    if (appEnv == 'dev') return true;
    if (appEnv == 'prod') return false;
    if (apiBaseUrl.isNotEmpty) {
      return apiBaseUrl == AppConstants.devBaseUrl;
    }
    return !releaseMode;
  }

  /// `true` for dev API / debug defaults / explicit `APP_ENV=dev`.
  static bool get isDev {
    ensureValidConfiguration();
    return resolveIsDev(
      appEnv: rawAppEnv,
      apiBaseUrl: rawApiBaseUrl,
      releaseMode: kReleaseMode,
    );
  }

  static bool get isProd => !isDev;

  static String get label => isDev ? 'DEV' : 'PROD';

  @visibleForTesting
  static bool get hasExplicitEnv => rawAppEnv.isNotEmpty;
}
