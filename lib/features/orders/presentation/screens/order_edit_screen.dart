import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../domain/providers/order_provider.dart';
import '../../domain/utils/orders_api_utils.dart';
import '../widgets/manage_orders_guard.dart';
import '../widgets/order_form.dart';

class OrderEditScreen extends ConsumerWidget {
  const OrderEditScreen({super.key, required this.orderId});

  final String orderId;

  OrderDetailKey? _key(WidgetRef ref) {
    final shopId = ref.watch(shopProvider.select((s) => s.selected?.id));
    if (shopId == null) return null;
    return (shopId: shopId, orderId: orderId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final key = _key(ref);
    final busy = ref.watch(orderMutationsProvider);

    if (key == null) {
      return ManageOrdersGuard(
        child: Scaffold(
          appBar: AppBar(title: Text(s.ordersEditTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final detail = ref.watch(orderDetailProvider(key));

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(title: Text(s.ordersEditTitle)),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: ordersErrorIsForbidden(e)
                ? EmptyStateWidget(
                    icon: Icons.lock_outline,
                    title: s.noPermissionTitle,
                    subtitle: s.noPermissionDesc,
                  )
                : Text(ordersUserErrorMessage(e, s)),
          ),
          data: (order) {
            if (order == null) {
              return EmptyStateWidget(
                icon: Icons.search_off_outlined,
                title: s.ordersNotFound,
              );
            }
            if (!order.isActive) {
              return EmptyStateWidget(
                icon: Icons.info_outline,
                title: s.ordersNotActiveEdit,
              );
            }
            return OrderForm(
              order: order,
              isSubmitting: busy,
              onSubmit: (payload) async {
                try {
                  final updated = await ref
                      .read(orderMutationsProvider.notifier)
                      .updateOrder(order.id, payload);
                  if (updated == null || !context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.ordersUpdated)));
                  context.pop();
                } on ApiException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ordersUserErrorMessage(e, s))),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
