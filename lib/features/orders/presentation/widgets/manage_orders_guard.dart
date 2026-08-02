import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/shop_permissions.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// `manage_orders` ruxsati yo‘q bo‘lsa — lokalizatsiyalangan empty state.
/// Shop yoki permission o‘zgarganda avtomatik qayta chiziladi.
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
    final allowed = ref.watch(hasPermissionProvider(ShopPermissions.manageOrders));

    if (allowed) return child;

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
          title: s.noPermissionTitle,
          subtitle: s.noPermissionDesc,
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
