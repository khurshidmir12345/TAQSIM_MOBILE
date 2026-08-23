import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/shop_features.dart';
import '../../../../core/constants/shop_permissions.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Buyurtmalar va mijozlar ekranlarining qorovuli.
///
/// Ikki mustaqil shart tekshiriladi:
///  * `manage_orders` ruxsati — roldan kelib chiqadi (egasi/xodim);
///  * `orders` bo'limi — hisob muddatidan kelib chiqadi.
///
/// Ikkalasining xabari ham neytral: birinchisi ruxsat haqida, ikkinchisi
/// hisob holati haqida. Hech qaysisi biror narsa sotib olishga chaqirmaydi.
///
/// Shop, ruxsat yoki muddat o‘zgarganda avtomatik qayta chiziladi.
class ManageOrdersGuard extends ConsumerWidget {
  const ManageOrdersGuard({
    super.key,
    required this.child,
    this.onDenied,
  });

  final Widget child;
  final VoidCallback? onDenied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final hasPermission =
        ref.watch(hasPermissionProvider(ShopPermissions.manageOrders));
    final hasFeature = ref.watch(hasFeatureProvider(ShopFeatures.orders));

    if (hasPermission && hasFeature) return child;

    // Ruxsat yo'qligi kuchliroq sabab: xodimga bo'lim ochilsa ham u
    // baribir kira olmaydi.
    final title = hasPermission ? s.featureNotEnabledTitle : s.noPermissionTitle;
    final subtitle =
        hasPermission ? s.featureNotEnabledDesc : s.noPermissionDesc;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/shell');
        }
      },
      child: Scaffold(
        appBar: AppBar(),
        body: EmptyStateWidget(
          icon: Icons.lock_outline,
          title: title,
          subtitle: subtitle,
          actionLabel: s.backToDashboard,
          onAction: onDenied ??
              () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/shell');
                }
              },
        ),
      ),
    );
  }
}
