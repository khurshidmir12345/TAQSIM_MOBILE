import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/translations.dart';
import '../../domain/models/customer_order_model.dart';
import '../../domain/utils/money_utils.dart';
import 'order_status_badge.dart';

/// Ixcham zakaz kartasi — butun karta bosilganda tafsilotlar ochiladi.
/// Qo'ng'iroq va topshirish — o'ngdagi kichik icon tugmalar.
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

  double get _paid => roundMoney(parseAmount(order.paidAmount));

  double get _remaining => roundMoney(parseAmount(order.remainingAmount));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final phone = order.customer?.phone;
    final time = formatDeliveryTime(order.deliveryTime);
    final itemsLine = _itemsLine();

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _TimeBox(time: time),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer?.name ?? '—',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (itemsLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        itemsLine,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 7),
                    // Summalar bir qatorda — sig'masa proporsional kichrayadi.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          if (!order.isActive) ...[
                            OrderStatusBadge(status: order.status),
                            const SizedBox(width: 8),
                          ],
                          if (showDate) ...[
                            Icon(
                              Icons.event_outlined,
                              size: 12,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              formatDeliveryDate?.call(order.deliveryDate) ??
                                  order.deliveryDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _MoneyStat(
                            label: s.ordersTotalLabel,
                            value: formatMoney(
                              parseAmount(order.totalAmount),
                            ),
                            color: cs.onSurface,
                          ),
                          _StatDot(color: cs.onSurface),
                          _MoneyStat(
                            label: s.ordersSummaryPaid,
                            value: formatMoney(parseAmount(order.paidAmount)),
                            color: _paid > 0
                                ? cs.tertiary
                                : cs.onSurface.withValues(alpha: 0.45),
                          ),
                          _StatDot(color: cs.onSurface),
                          _MoneyStat(
                            label: s.ordersRemainingLabel,
                            value: formatMoney(_remaining),
                            color: _remaining > 0 ? cs.error : cs.tertiary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (phone != null && phone.isNotEmpty)
                _ActionIcon(
                  icon: Icons.phone_outlined,
                  tooltip: phone,
                  foreground: cs.onSurface.withValues(alpha: 0.6),
                  background: cs.onSurface.withValues(alpha: 0.05),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _callPhone(phone);
                  },
                ),
              if (order.isActive && onDeliver != null) ...[
                const SizedBox(width: 8),
                _ActionIcon(
                  icon: Icons.check_rounded,
                  tooltip: s.ordersDeliverAction,
                  foreground: cs.primary,
                  background: cs.primary.withValues(alpha: 0.1),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDeliver!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chapdagi vaqt katakchasi — vaqt bo'lmasa neytral belgi ko'rsatiladi.
class _TimeBox extends StatelessWidget {
  const _TimeBox({this.time});

  final String? time;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: time != null
          ? Text(
              time!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            )
          : Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: cs.primary.withValues(alpha: 0.7),
            ),
    );
  }
}

/// "Yorliq + summa" juftligi — kartadagi pul qatori uchun.
class _MoneyStat extends StatelessWidget {
  const _MoneyStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Statlar orasidagi kichik ajratuvchi nuqta.
class _StatDot extends StatelessWidget {
  const _StatDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: foreground),
          ),
        ),
      ),
    );
  }
}
