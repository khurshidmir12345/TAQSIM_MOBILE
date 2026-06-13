import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/wallet_transaction_model.dart';
import '../../domain/providers/subscription_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.invalidate(walletTransactionsProvider);
      ref.read(subscriptionStatusProvider.notifier).refresh();
    });
  }

  String _fmt(double v) => NumberFormat('#,##0', 'uz').format(v);

  String _typeLabel(S s, String type) => switch (type) {
        'topup' => s.txnTopup,
        'subscription_charge' => s.txnSubscription,
        'refund' => s.txnRefund,
        _ => s.txnAdjustment,
      };

  String _date(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());
  }

  Future<void> _openTopUp(BuildContext context) async {
    // Balans to'ldirish endi alohida ekran (karta + chek + admin tasdiqlovi).
    await context.push('/top-up');
    if (!mounted) return;
    ref.invalidate(walletTransactionsProvider);
    await ref.read(subscriptionStatusProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final txnsAsync = ref.watch(walletTransactionsProvider);

    final balance = statusAsync.maybeWhen(
      data: (st) => st.balance,
      orElse: () => 0.0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.walletTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletTransactionsProvider);
          await ref.read(subscriptionStatusProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _BalanceHeader(
              balance: _fmt(balance),
              onTopUp: () => _openTopUp(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.balanceHistory,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            txnsAsync.when(
              loading: () => const SkeletonLoader(itemHeight: 64),
              error: (e, _) => ErrorRetryWidget(
                message: e is ApiException ? e.message : e.toString(),
                onRetry: () => ref.invalidate(walletTransactionsProvider),
              ),
              data: (txns) {
                if (txns.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: s.noTransactions,
                      subtitle: s.noTransactionsDesc,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final txn in txns)
                      _TxnTile(
                        txn: txn,
                        label: _typeLabel(s, txn.type),
                        date: _date(txn.createdAt),
                        amount: _fmt(txn.amount.abs()),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final String balance;
  final VoidCallback onTopUp;

  const _BalanceHeader({required this.balance, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                s.balance,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$balance UZS',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTopUp,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.topUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final WalletTransactionModel txn;
  final String label;
  final String date;
  final String amount;

  const _TxnTile({
    required this.txn,
    required this.label,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = txn.isCredit ? AppColors.primary : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              txn.isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description?.isNotEmpty == true ? txn.description! : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${txn.isCredit ? '+' : '−'}$amount',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
