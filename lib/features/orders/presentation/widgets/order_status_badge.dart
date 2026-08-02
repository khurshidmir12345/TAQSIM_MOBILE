import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/customer_order_model.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final CustomerOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    final (label, bg, fg) = switch (status) {
      CustomerOrderStatus.active => (
        s.ordersStatusActive,
        cs.primary.withValues(alpha: 0.12),
        cs.primary,
      ),
      CustomerOrderStatus.delivered => (
        s.ordersStatusDelivered,
        cs.tertiary.withValues(alpha: 0.15),
        cs.tertiary,
      ),
      CustomerOrderStatus.cancelled => (
        s.ordersStatusCancelled,
        cs.onSurface.withValues(alpha: 0.08),
        cs.onSurface.withValues(alpha: 0.55),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
