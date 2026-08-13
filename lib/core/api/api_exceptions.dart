import 'package:dio/dio.dart';

import '../l10n/api_locale_holder.dart';
import '../l10n/translations.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Backend biznes-kodi (masalan: account_blocked, phone_taken).
  final String? code;

  /// Xato javobidagi qo'shimcha `data`.
  final Map<String, dynamic>? data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.data,
  });

  factory ApiException.invalidResponse() => ApiException(
        message: S.apiClientString(
          ApiLocaleHolder.code,
          'apiInvalidResponseFormat',
        ),
      );

  bool get isAccountBlocked => code == 'account_blocked';
  bool get isPhoneTaken => code == 'phone_taken';
  bool get isInviteExpired => code == 'invite_expired';
  bool get isInvalidCode => code == 'invalid_code';

  factory ApiException.fromDioException(DioException e) {
    final loc = ApiLocaleHolder.code;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: S.apiClientString(loc, 'apiClientTimeout'),
        );
      case DioExceptionType.badResponse:
        final data = e.response?.data;

        // 422 da `message` doim umumiy ("Ma'lumotlar noto'g'ri"), aniq sabab
        // esa `errors` ichida bo'ladi. Ilgari faqat `message` ko'rsatilardi va
        // foydalanuvchi nima xato ekanini bilmasdi — masalan kod eskirganini.
        final fieldError = _firstFieldError(data);
        final raw = fieldError ?? (data is Map ? data['message'] : null);
        final text = raw?.toString().trim();
        final message = (text != null && text.isNotEmpty)
            ? text
            : S.apiClientString(loc, 'snackbarErrorGeneric');
        return ApiException(
          message: message,
          statusCode: e.response?.statusCode,
          code: data is Map ? data['code']?.toString() : null,
          data: data is Map && data['data'] is Map
              ? Map<String, dynamic>.from(data['data'] as Map)
              : null,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: S.apiClientString(loc, 'apiClientNoConnection'),
        );
      default:
        return ApiException(
          message: S.apiClientString(loc, 'apiClientUnexpected'),
        );
    }
  }

  /// Laravel validatsiya javobidagi birinchi maydon xatosi.
  ///
  /// Shakli: `{"errors": {"code": ["Kod noto'g'ri..."]}}`.
  /// Topilmasa `null` — chaqiruvchi umumiy xabarga qaytadi.
  static String? _firstFieldError(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];

    if (errors is! Map) return null;

    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        final first = value.first?.toString().trim();

        if (first != null && first.isNotEmpty) return first;
      } else if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  @override
  String toString() => message;
}
