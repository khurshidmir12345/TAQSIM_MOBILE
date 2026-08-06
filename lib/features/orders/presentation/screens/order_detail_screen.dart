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
import '../widgets/initials_avatar.dart';
import '../widgets/manage_orders_guard.dart';
import '../widgets/order_status_badge.dart';

enum _OrderMenuAction { edit, cancel, delete }

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

  String _fmtDateTime(BuildContext context, String? raw) {
    return formatDateTimeLocale(raw, localeTag: _localeTag(context));
  }

  Future<void> _refresh(WidgetRef ref, OrderDetailKey key) async {
    await ref.read(orderDetailProvider(key).notifier).refresh();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/shell');
    }
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
        _goBack(context);
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
    final key = _key(ref);
    final busy = ref.watch(orderMutationsProvider);

    if (key == null) {
      return ManageOrdersGuard(
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => _goBack(context)),
            title: Text(s.ordersDetailTitle),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final detail = ref.watch(orderDetailProvider(key));

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _goBack(context)),
          title: Text(s.ordersDetailTitle),
          actions: [
            if (detail.value != null && detail.value!.isActive)
              PopupMenuButton<_OrderMenuAction>(
                enabled: !busy,
                icon: const Icon(Icons.more_vert),
                onSelected: (action) async {
                  final order = detail.value!;
                  switch (action) {
                    case _OrderMenuAction.edit:
                      await context.push('/orders/${order.id}/edit');
                      if (context.mounted) await _refresh(ref, key);
                    case _OrderMenuAction.cancel:
                      await _cancel(context, ref, order, key);
                    case _OrderMenuAction.delete:
                      await _delete(context, ref, order);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _OrderMenuAction.edit,
                    child: _MenuRow(
                      icon: Icons.edit_outlined,
                      label: s.ordersEditTitle,
                    ),
                  ),
                  PopupMenuItem(
                    value: _OrderMenuAction.cancel,
                    child: _MenuRow(
                      icon: Icons.block_outlined,
                      label: s.ordersCancelOrder,
                    ),
                  ),
                  if (detail.value!.canDelete)
                    PopupMenuItem(
                      value: _OrderMenuAction.delete,
                      child: _MenuRow(
                        icon: Icons.delete_outline,
                        label: s.delete,
                        destructive: true,
                      ),
                    ),
                ],
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
            return _OrderDetailBody(
              order: order,
              busy: busy,
              onRefresh: () => _refresh(ref, key),
              formatMoney: (v) => _fmtMoney(context, v),
              formatDate: (raw) =>
                  formatDateOnlyLocale(raw, localeTag: _localeTag(context)),
              formatDateTime: (raw) => _fmtDateTime(context, raw),
              onCall: _callPhone,
            );
          },
        ),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({
    required this.order,
    required this.busy,
    required this.onRefresh,
    required this.formatMoney,
    required this.formatDate,
    required this.formatDateTime,
    required this.onCall,
  });

  final CustomerOrderModel order;
  final bool busy;
  final Future<void> Function() onRefresh;
  final String Function(num value) formatMoney;
  final String Function(String raw) formatDate;
  final String Function(String? raw) formatDateTime;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final customer = order.customer;
    final remaining = roundMoney(parseAmount(order.remainingAmount));
    final time = formatDeliveryTime(order.deliveryTime);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          // ─── Mijoz ───
          _SectionCard(
            child: Row(
              children: [
                InitialsAvatar(name: customer?.name ?? '—'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer?.name ?? '—',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                ),
                if (customer?.phone != null && customer!.phone!.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onCall(customer.phone!);
                    },
                    tooltip: customer.phone,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary.withValues(alpha: 0.08),
                      foregroundColor: cs.primary,
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // ─── Topshirish ma'lumotlari ───
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.event_outlined,
                  text: time != null
                      ? '${formatDate(order.deliveryDate)} · $time'
                      : formatDate(order.deliveryDate),
                ),
                if (order.status == CustomerOrderStatus.delivered &&
                    order.deliveredAt != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.check_circle_outline,
                    iconColor: cs.tertiary,
                    text:
                        '${s.ordersDeliveredAt}: ${formatDateTime(order.deliveredAt)}',
                  ),
                ],
                if (order.note != null && order.note!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.notes_outlined, text: order.note!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // ─── Mahsulotlar va summa ───
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.shopping_basket_outlined,
                  label: s.ordersItemsTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.breadCategory?.name ?? '—',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${item.quantity} × ${formatMoney(parseAmount(item.unitPrice))}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatMoney(parseAmount(item.subtotal)),
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(),
                ),
                _SummaryRow(
                  label: s.ordersTotalLabel,
                  value: formatMoney(parseAmount(order.totalAmount)),
                ),
                _SummaryRow(
                  label: s.ordersSummaryPaid,
                  value: formatMoney(parseAmount(order.paidAmount)),
                  valueColor: cs.tertiary,
                ),
                _SummaryRow(
                  label: s.ordersRemainingLabel,
                  value: formatMoney(remaining),
                  valueColor: remaining > 0 ? cs.error : cs.tertiary,
                  emphasized: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // ─── To'lovlar ───
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SectionTitle(
                        icon: Icons.payments_outlined,
                        label: s.ordersPaymentsTitle,
                      ),
                    ),
                    if (order.isActive && remaining > 0)
                      IconButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final changed = await showAddPaymentSheet(
                                  context,
                                  order: order,
                                );
                                if (changed == true && context.mounted) {
                                  await onRefresh();
                                }
                              },
                        tooltip: s.ordersAddPayment,
                        style: IconButton.styleFrom(
                          backgroundColor: cs.primary.withValues(alpha: 0.08),
                          foregroundColor: cs.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                      ),
                  ],
                ),
                if (order.payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.ordersNoPayments,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                else
                  for (final p in order.payments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: cs.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatMoney(parseAmount(p.amount)),
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (p.paidAt != null ||
                                    (p.note != null && p.note!.isNotEmpty))
                                  Text(
                                    [
                                      if (p.paidAt != null)
                                        formatDateTime(p.paidAt),
                                      if (p.note != null && p.note!.isNotEmpty)
                                        p.note!,
                                    ].join(' · '),
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),

          // ─── Asosiy amal ───
          if (order.isActive) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      HapticFeedback.selectionClick();
                      final changed = await showDeliverOrderSheet(
                        context,
                        order: order,
                      );
                      if (changed == true && context.mounted) {
                        await onRefresh();
                      }
                    },
              icon: const Icon(Icons.check_rounded),
              label: Text(s.ordersDeliverAction),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? cs.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 15 : 14,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 16 : 14,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = destructive ? cs.error : cs.onSurface;

    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
