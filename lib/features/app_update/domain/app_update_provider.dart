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

/// Modalka shu seansda allaqachon ko'rsatilganmi.
///
/// Asosiy sahifa qayta qurilishi mumkin (tab almashish, ruxsatlar yangilanishi,
/// logout/login) — modalka esa ilovaga bir kirishda bir marta chiqishi kerak.
class AppUpdatePromptShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

final appUpdatePromptShownProvider =
    NotifierProvider<AppUpdatePromptShownNotifier, bool>(
  AppUpdatePromptShownNotifier.new,
);
