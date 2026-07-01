import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../l10n/api_locale_holder.dart';

typedef LogoutCallback = FutureOr<void> Function();
typedef SubscriptionBlockedCallback = void Function();

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;
  LogoutCallback? _onForceLogout;
  SubscriptionBlockedCallback? _onSubscriptionBlocked;

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Accept-Language': ApiLocaleHolder.code,
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    dio.interceptors.add(_JsonParseInterceptor());
    dio.interceptors.add(_AuthInterceptor(this));
  }

  static String _resolveBaseUrl() => AppConstants.baseUrl;

  void setAcceptLanguage(String code) {
    dio.options.headers['Accept-Language'] = code;
  }

  /// Multi-device sessiya uchun qurilma metama'lumotini barcha so'rovlarga qo'shadi
  /// (backend login/register paytida saqlaydi).
  void setDeviceHeaders({
    String? deviceName,
    String? platform,
    String? appVersion,
  }) {
    final name = _asciiHeaderValue(deviceName);
    if (name != null && name.isNotEmpty) {
      dio.options.headers['X-Device-Name'] = name;
    }
    if (platform != null && platform.isNotEmpty) {
      dio.options.headers['X-Device-Platform'] = platform;
    }
    if (appVersion != null && appVersion.isNotEmpty) {
      dio.options.headers['X-App-Version'] = appVersion;
    }
  }

  /// HTTP header qiymatlari faqat printable ASCII bo'lishi shart.
  /// Qurilma nomidagi `·`, `’`, emoji kabi belgilar `FormatException` keltirib
  /// chiqaradi va so'rovni butunlay uzadi — shu sabab xavfsiz tozalaymiz.
  String? _asciiHeaderValue(String? value) {
    if (value == null) return null;
    final buffer = StringBuffer();
    for (final code in value.codeUnits) {
      if (code >= 0x20 && code <= 0x7E) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }

  void setLogoutCallback(LogoutCallback callback) {
    _onForceLogout = callback;
  }

  void setSubscriptionBlockedCallback(SubscriptionBlockedCallback callback) {
    _onSubscriptionBlocked = callback;
  }

  void notifySubscriptionBlocked() {
    _onSubscriptionBlocked?.call();
  }

  Future<void> forceLogout() async {
    clearToken();
    if (_onForceLogout != null) {
      await _onForceLogout!();
    }
  }
}

class _JsonParseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is String && (response.data as String).isNotEmpty) {
      try {
        response.data = jsonDecode(response.data as String);
      } catch (_) {}
    }
    handler.next(response);
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  bool _isLoggingOut = false;

  _AuthInterceptor(this._client);

  static const _authPaths = ['/auth/login', '/auth/register', '/auth/send-code', '/auth/logout', '/auth/telegram/'];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthEndpoint = _authPaths.any(path.contains);
      if (!isAuthEndpoint && !_isLoggingOut) {
        _isLoggingOut = true;
        _client.forceLogout().whenComplete(() => _isLoggingOut = false);
      }
    }

    if (err.response?.statusCode == 402) {
      final data = err.response?.data;
      final code = data is Map ? data['code']?.toString() : null;
      if (code == 'subscription_required') {
        _client.notifySubscriptionBlocked();
      }
    }

    handler.next(err);
  }
}
