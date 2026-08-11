import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../data/app_update_repository.dart';
import 'models/app_update_info.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(ref.read(apiClientProvider)),
);

/// Ilova ochilganda bir marta tekshiriladi.
///
/// Tarmoq xatosi jim yutiladi: yangilanish tekshiruvi tufayli ilova
/// ochilmay qolishi yoki xato ko'rsatishi mumkin emas.
final appUpdateCheckProvider = FutureProvider<AppUpdateInfo>((ref) async {
  try {
    return await ref.read(appUpdateRepositoryProvider).check();
  } catch (_) {
    return const AppUpdateInfo.none();
  }
});
