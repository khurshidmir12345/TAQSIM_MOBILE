import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/providers/order_provider.dart';
import '../../domain/utils/orders_api_utils.dart';
import '../widgets/manage_orders_guard.dart';
import '../widgets/order_form.dart';

class OrderCreateScreen extends ConsumerWidget {
  const OrderCreateScreen({super.key, this.initialCustomer});

  final CustomerModel? initialCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final busy = ref.watch(orderMutationsProvider);

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(title: Text(s.ordersNewTitle)),
        body: OrderForm(
          initialCustomer: initialCustomer,
          isSubmitting: busy,
          onSubmit: (payload) async {
            try {
              final order = await ref
                  .read(orderMutationsProvider.notifier)
                  .createOrder(payload);
              if (order == null || !context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(s.ordersCreated)));
              context.go('/orders/${order.id}');
            } on ApiException catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ordersUserErrorMessage(e, s))),
              );
            }
          },
        ),
      ),
    );
  }
}
