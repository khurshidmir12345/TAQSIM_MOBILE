import 'package:dio/dio.dart';

import '../l10n/api_locale_holder.dart';
import '../l10n/translations.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Backend biznes-kodi (masalan: subscription_required,
  /// plan_limit_reached, insufficient_balance).
  final String? code;

  /// Xato javobidagi qo'shimcha `data` (limit/usage, shortfall va h.k.).
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

  bool get isSubscriptionRequired => code == 'subscription_required';
  bool get isGraceReadOnly => code == 'subscription_grace_readonly';
  bool get isPlanLimitReached => code == 'plan_limit_reached';
  bool get isInsufficientBalance => code == 'insufficient_balance';
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
        final raw = data is Map ? data['message'] : null;
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

  @override
  String toString() => message;
}
