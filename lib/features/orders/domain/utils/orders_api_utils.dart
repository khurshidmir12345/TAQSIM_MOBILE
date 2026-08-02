import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/translations.dart';

extension ApiExceptionOrders on ApiException {
  bool get isForbiddenPermission =>
      statusCode == 403 ||
      code == 'forbidden_permission' ||
      code == 'forbidden';
}

/// Foydalanuvchiga ko‘rsatiladigan xabar — hech qachon `DioException`/`toString`.
String ordersUserErrorMessage(Object error, S strings) {
  if (error is ApiException) {
    if (error.isForbiddenPermission) {
      return strings.noPermissionDesc;
    }
    return error.message;
  }
  return strings.snackbarErrorGeneric;
}

bool ordersErrorIsForbidden(Object error) {
  return error is ApiException && error.isForbiddenPermission;
}

/// Provider/state uchun — faqat ApiException xabari, hech qachon toString.
String ordersProviderErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return '';
}
