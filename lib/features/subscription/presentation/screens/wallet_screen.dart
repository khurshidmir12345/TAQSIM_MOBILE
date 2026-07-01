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
    final info = ref.read(topupInfoProvider).asData?.value;
    if (info != null && !info.topupEnabled) {
      _showMaintenanceSheet(context);
      return;
    }
    await context.push('/top-up');
    if (!mounted) return;
    ref.invalidate(walletTransactionsProvider);
    await ref.read(subscriptionStatusProvider.notifier).refresh();
  }

  void _showMaintenanceSheet(BuildContext context) {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TopupMaintenanceSheet(
        title: s.topUpComingSoonTitle,
        desc: s.topUpComingSoonDesc,
      ),
    );
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

class _TopupMaintenanceSheet extends StatefulWidget {
  final String title;
  final String desc;

  const _TopupMaintenanceSheet({required this.title, required this.desc});

  @override
  State<_TopupMaintenanceSheet> createState() => _TopupMaintenanceSheetState();
}

class _TopupMaintenanceSheetState extends State<_TopupMaintenanceSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Transform.scale(
              scale: _scale.value,
              child: Opacity(opacity: _fade.value, child: child),
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            widget.desc,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
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
