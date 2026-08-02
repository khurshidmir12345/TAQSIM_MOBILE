import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/customer_order_model.dart';
import '../../domain/utils/money_utils.dart';
import 'order_payment_badge.dart';
import 'order_status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.formatMoney,
    required this.onTap,
    this.showDate = false,
    this.formatDeliveryDate,
    this.onDeliver,
  });

  final CustomerOrderModel order;
  final String Function(num value) formatMoney;
  final VoidCallback onTap;
  final bool showDate;
  final String Function(String raw)? formatDeliveryDate;
  final VoidCallback? onDeliver;

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _itemsLine() {
    if (order.items.isEmpty) return '';
    return order.items
        .map((i) {
          final name = i.breadCategory?.name ?? '';
          return '${i.quantity} ${name.isNotEmpty ? name : ''}'.trim();
        })
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final customer = order.customer;
    final phone = customer?.phone;
    final time = formatDeliveryTime(order.deliveryTime);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_itemsLine().isNotEmpty)
                                  Text(
                                    _itemsLine(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  customer?.name ?? '—',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (time != null)
                            Text(
                              time,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                            ),
                        ],
                      ),
                      if (showDate) ...[
                        const SizedBox(height: 4),
                        Text(
                          formatDeliveryDate?.call(order.deliveryDate) ??
                              order.deliveryDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Spacer(),
                          OrderPaymentBadge(
                            order: order,
                            formatMoney: formatMoney,
                          ),
                        ],
                      ),
                      if (order.status != CustomerOrderStatus.active) ...[
                        const SizedBox(height: AppSpacing.sm),
                        OrderStatusBadge(status: order.status),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _callPhone(phone);
                  },
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: Text(phone),
                ),
              ),
            ],
            if (order.isActive && onDeliver != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDeliver!();
                  },
                  child: Text(s.ordersDeliverAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
