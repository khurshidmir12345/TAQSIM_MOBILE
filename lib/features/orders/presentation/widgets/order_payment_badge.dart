import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/customer_order_model.dart';
import '../../domain/utils/money_utils.dart';

enum OrderPaymentState { paid, partial, unpaid }

OrderPaymentState orderPaymentState(CustomerOrderModel order) {
  final remaining = roundMoney(parseAmount(order.remainingAmount));
  final paid = roundMoney(parseAmount(order.paidAmount));
  if (remaining <= 0) return OrderPaymentState.paid;
  if (paid > 0) return OrderPaymentState.partial;
  return OrderPaymentState.unpaid;
}

class OrderPaymentBadge extends StatelessWidget {
  const OrderPaymentBadge({
    super.key,
    required this.order,
    required this.formatMoney,
  });

  final CustomerOrderModel order;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final state = orderPaymentState(order);

    final (label, bg, fg) = switch (state) {
      OrderPaymentState.paid => (
        s.ordersPaid,
        cs.tertiary.withValues(alpha: 0.15),
        cs.tertiary,
      ),
      OrderPaymentState.partial => (
        s.ordersPartiallyPaid
            .replaceAll('{paid}', formatMoney(parseAmount(order.paidAmount)))
            .replaceAll(
              '{remaining}',
              formatMoney(parseAmount(order.remainingAmount)),
            ),
        cs.primary.withValues(alpha: 0.1),
        cs.primary,
      ),
      OrderPaymentState.unpaid => (
        s.ordersUnpaid,
        cs.error.withValues(alpha: 0.1),
        cs.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
