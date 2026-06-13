import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../data/device_repository.dart';
import '../models/device_model.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.read(apiClientProvider));
});

/// Foydalanuvchining aktiv qurilmalari (sessiyalari).
final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, List<DeviceModel>>(
  DevicesNotifier.new,
);

class DevicesNotifier extends AsyncNotifier<List<DeviceModel>> {
  @override
  Future<List<DeviceModel>> build() {
    return ref.read(deviceRepositoryProvider).getDevices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(deviceRepositoryProvider).getDevices(),
    );
  }

  /// Tanlangan qurilmani chiqaradi va ro'yxatni darhol yangilaydi.
  Future<bool> revoke(String id) async {
    try {
      await ref.read(deviceRepositoryProvider).revokeDevice(id);
      final current = state.asData?.value ?? const [];
      state = AsyncData(current.where((d) => d.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}
