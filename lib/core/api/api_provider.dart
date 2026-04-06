import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.listen<AsyncValue<AppLocale>>(localeProvider, (_, next) {
    if (next case AsyncData(:final value)) {
      client.setAcceptLanguage(value.code);
    }
  }, fireImmediately: true);
  return client;
});
