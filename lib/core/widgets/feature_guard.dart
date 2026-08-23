import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/translations.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import 'empty_state_widget.dart';

/// Bo'lim hisobda ochiq bo'lmasa — neytral holat xabari.
///
/// Ataylab tugmasiz va havolasiz: xabar shunchaki hisob holatini bildiradi,
/// biror narsa sotib olishga chaqirmaydi. Nima qilish kerakligini
/// foydalanuvchi ilovadan tashqarida — Telegram orqali — biladi.
///
/// O'z AppBar'i bor ekranlar buni widget sifatida emas, [lockedBody] orqali
/// ishlatadi: yopiq holat ham odatdagi ekranday ko'rinsin.
class FeatureGuard extends ConsumerWidget {
  const FeatureGuard({
    super.key,
    required this.feature,
    required this.child,
    this.appBar,
  });

  /// `ShopFeatures` dagi kalit.
  final String feature;

  final Widget child;

  /// Yopiq holatda ko'rsatiladigan AppBar.
  final PreferredSizeWidget? appBar;

  /// Yopiq bo'lim uchun umumiy ko'rinish.
  static Widget lockedBody(S s) {
    return EmptyStateWidget(
      icon: Icons.lock_outline,
      title: s.featureNotEnabledTitle,
      subtitle: s.featureNotEnabledDesc,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasFeatureProvider(feature))) return child;

    return Scaffold(
      appBar: appBar,
      body: lockedBody(S.of(context)),
    );
  }
}
