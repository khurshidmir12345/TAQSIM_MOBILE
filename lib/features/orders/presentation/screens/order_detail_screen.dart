import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../domain/models/customer_order_model.dart';
import '../../domain/providers/order_provider.dart';
import '../../domain/utils/money_utils.dart';
import '../../domain/utils/orders_api_utils.dart';
import '../widgets/add_payment_sheet.dart';
import '../widgets/deliver_order_sheet.dart';
import '../widgets/manage_orders_guard.dart';
import '../widgets/order_payment_badge.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  OrderDetailKey? _key(WidgetRef ref) {
    final shopId = ref.watch(shopProvider.select((s) => s.selected?.id));
    if (shopId == null) return null;
    return (shopId: shopId, orderId: orderId);
  }

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return localeTagFrom(l.languageCode, l.countryCode);
  }

  String _fmtMoney(BuildContext context, num value) {
    return formatMoneyAmount(value, localeTag: _localeTag(context));
  }

  String _fmtDeliveredAt(BuildContext context, String? raw) {
    return formatDateTimeLocale(raw, localeTag: _localeTag(context));
  }

  Future<void> _refresh(WidgetRef ref, OrderDetailKey key) async {
    await ref.read(orderDetailProvider(key).notifier).refresh();
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    CustomerOrderModel order,
    OrderDetailKey key,
  ) async {
    final s = S.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: s.ordersCancelTitle,
      message: s.ordersCancelDescription,
      confirmLabel: s.ordersCancelOrder,
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      final updated = await ref
          .read(orderMutationsProvider.notifier)
          .cancelOrder(order.id);
      if (updated != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.ordersCancelledToast)));
        await _refresh(ref, key);
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ordersUserErrorMessage(e, s))));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CustomerOrderModel order,
  ) async {
    final s = S.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: s.delete,
      message: s.ordersDeleteDescription,
      confirmLabel: s.delete,
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      final deleted = await ref
          .read(orderMutationsProvider.notifier)
          .deleteOrder(order.id);
      if (deleted && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.ordersDeletedToast)));
        context.go('/shell');
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ordersUserErrorMessage(e, s))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final key = _key(ref);
    final busy = ref.watch(orderMutationsProvider);

    if (key == null) {
      return ManageOrdersGuard(
        child: Scaffold(
          appBar: AppBar(title: Text(s.ordersDetailTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final detail = ref.watch(orderDetailProvider(key));

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.ordersDetailTitle),
          actions: [
            IconButton(
              onPressed: () => _refresh(ref, key),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: ordersErrorIsForbidden(e)
                ? EmptyStateWidget(
                    icon: Icons.lock_outline,
                    title: s.noPermissionTitle,
                    subtitle: s.noPermissionDesc,
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      ordersUserErrorMessage(e, s),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          data: (order) {
            if (order == null) {
              return EmptyStateWidget(
                icon: Icons.search_off_outlined,
                title: s.ordersNotFound,
              );
            }

            final customer = order.customer;
            final remaining = roundMoney(parseAmount(order.remainingAmount));

            return RefreshIndicator(
              onRefresh: () => _refresh(ref, key),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer?.name ?? '—',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                  if (order.status == CustomerOrderStatus.delivered &&
                      order.deliveredAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                      ),
                      child: Text(
                        '${s.ordersDeliveredAt}: ${_fmtDeliveredAt(context, order.deliveredAt)}',
                      ),
                    ),
                  ],
                  if (order.status == CustomerOrderStatus.cancelled) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                      ),
                      child: Text(s.ordersStatusCancelled),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (customer?.phone != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(customer!.phone!),
                      onTap: () => _callPhone(customer.phone!),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      formatDateOnlyLocale(
                        order.deliveryDate,
                        localeTag: _localeTag(context),
                      ),
                    ),
                    subtitle: formatDeliveryTime(order.deliveryTime) != null
                        ? Text(formatDeliveryTime(order.deliveryTime)!)
                        : null,
                  ),
                  if (order.note != null && order.note!.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notes_outlined),
                      title: Text(order.note!),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    s.ordersItemsTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...order.items.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.breadCategory?.name ?? '—'),
                      subtitle: Text(
                        '${item.quantity} × ${_fmtMoney(context, parseAmount(item.unitPrice))}',
                      ),
                      trailing: Text(
                        _fmtMoney(context, parseAmount(item.subtotal)),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  _SummaryRow(
                    label: s.ordersTotalLabel,
                    value: _fmtMoney(context, parseAmount(order.totalAmount)),
                  ),
                  _SummaryRow(
                    label: s.ordersSummaryPaid,
                    value: _fmtMoney(context, parseAmount(order.paidAmount)),
                    valueColor: cs.tertiary,
                  ),
                  _SummaryRow(
                    label: s.ordersRemainingLabel,
                    value: _fmtMoney(context, remaining),
                    valueColor: remaining > 0 ? cs.error : cs.tertiary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OrderPaymentBadge(
                    order: order,
                    formatMoney: (v) => _fmtMoney(context, v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.ordersPaymentsTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (order.isActive && remaining > 0)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  final changed = await showAddPaymentSheet(
                                    context,
                                    order: order,
                                  );
                                  if (changed == true && context.mounted) {
                                    await _refresh(ref, key);
                                  }
                                },
                          child: Text(s.ordersAddPayment),
                        ),
                    ],
                  ),
                  if (order.payments.isEmpty)
                    Text(s.ordersNoPayments)
                  else
                    ...order.payments.map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_fmtMoney(context, parseAmount(p.amount))),
                        subtitle: Text(
                          [
                            if (p.paidAt != null)
                              _fmtDeliveredAt(context, p.paidAt),
                            if (p.note != null && p.note!.isNotEmpty) p.note!,
                          ].join(' · '),
                        ),
                      ),
                    ),
                  if (order.isActive) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () async {
                              HapticFeedback.selectionClick();
                              final changed = await showDeliverOrderSheet(
                                context,
                                order: order,
                              );
                              if (changed == true && context.mounted) {
                                await _refresh(ref, key);
                              }
                            },
                      child: Text(s.ordersDeliverAction),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => context.push('/orders/${order.id}/edit'),
                      child: Text(s.ordersEditTitle),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => _cancel(context, ref, order, key),
                      child: Text(s.ordersCancelOrder),
                    ),
                    if (order.canDelete) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => _delete(context, ref, order),
                        child: Text(
                          s.delete,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}
