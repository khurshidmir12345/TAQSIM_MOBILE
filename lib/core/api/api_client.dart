import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../l10n/api_locale_holder.dart';

typedef LogoutCallback = FutureOr<void> Function();

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;
  LogoutCallback? _onForceLogout;

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
          error: true,
        ),
      );
    }

    dio.interceptors.add(_JsonParseInterceptor());
    dio.interceptors.add(_AuthInterceptor(this));
  }

  static String _resolveBaseUrl() {
    if (kIsWeb) return AppConstants.baseUrl;

    if (Platform.isAndroid) {
      return AppConstants.baseUrlAndroidEmulator;
    }
    return AppConstants.baseUrlIosSimulator;
  }

  void setAcceptLanguage(String code) {
    dio.options.headers['Accept-Language'] = code;
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

  _AuthInterceptor(this._client);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _client.forceLogout();
    }
    handler.next(err);
  }
}
