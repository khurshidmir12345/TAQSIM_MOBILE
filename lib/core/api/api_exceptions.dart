import 'package:dio/dio.dart';

import '../l10n/api_locale_holder.dart';
import '../l10n/translations.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  factory ApiException.invalidResponse() => ApiException(
        message: S.apiClientString(
          ApiLocaleHolder.code,
          'apiInvalidResponseFormat',
        ),
      );

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
