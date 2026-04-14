import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/domain/providers/auth_provider.dart';

const _kPrefix = 'hint_dismissed_';

class ShopTutorialNotifier extends Notifier<bool> {
  /// true = hint ko'rsatilishi kerak, false = yo'q
  @override
  bool build() {
    final shopId = ref.watch(shopProvider).selected?.id;
    if (shopId == null) return false;

    _loadDismissed(shopId);
    return false;
  }

  Future<void> _loadDismissed(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('$_kPrefix$shopId') ?? false;
    if (!dismissed) {
      state = true;
    }
  }

  Future<void> dismiss() async {
    state = false;
    final shopId = ref.read(shopProvider).selected?.id;
    if (shopId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kPrefix$shopId', true);
  }
}

final shopTutorialProvider =
    NotifierProvider<ShopTutorialNotifier, bool>(
  ShopTutorialNotifier.new,
);
