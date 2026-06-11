import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../subscription/domain/providers/subscription_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  String _fmt(double v) => NumberFormat('#,##0', 'uz').format(v);

  String _date(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());
  }

  ({String label, Color color}) _status(S s, String status) => switch (status) {
        'paid' => (label: s.statusPaid, color: AppColors.primary),
        'pending' => (label: s.statusPending, color: AppColors.gold),
        'failed' => (label: s.statusFailed, color: AppColors.error),
        _ => (label: s.statusCancelled, color: Colors.grey),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.orders)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersListProvider),
        child: ordersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SkeletonLoader(itemCount: 6, itemHeight: 72),
          ),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              ErrorRetryWidget(
                message: e is ApiException ? e.message : e.toString(),
                onRetry: () => ref.invalidate(ordersListProvider),
              ),
            ],
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  EmptyStateWidget(
                    icon: Icons.shopping_bag_outlined,
                    title: s.noOrders,
                    subtitle: s.noOrdersDesc,
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final order = orders[i];
                final status = _status(s, order.status);
                final isTopup = order.type == 'topup';
                return _OrderTile(
                  title: isTopup
                      ? s.orderTopup
                      : (order.planName ?? s.orderSubscription),
                  subtitle: '${order.orderNumber} · ${_date(order.createdAt)}',
                  amount: '${_fmt(order.amountLocal)} ${order.currencyCode}',
                  icon: isTopup
                      ? Icons.account_balance_wallet_outlined
                      : Icons.workspace_premium_outlined,
                  statusLabel: status.label,
                  statusColor: status.color,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final String statusLabel;
  final Color statusColor;

  const _OrderTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
