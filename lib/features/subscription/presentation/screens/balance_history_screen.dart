import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/wallet_transaction_model.dart';
import '../../domain/providers/subscription_provider.dart';

/// Balans tarixi — kirim/chiqimlar zamonaviy, kunlar bo'yicha guruhlangan ko'rinishda.
/// Faqat biznes egasiga (owner) ko'rsatiladi.
class BalanceHistoryScreen extends ConsumerStatefulWidget {
  const BalanceHistoryScreen({super.key});

  @override
  ConsumerState<BalanceHistoryScreen> createState() =>
      _BalanceHistoryScreenState();
}

class _BalanceHistoryScreenState extends ConsumerState<BalanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(authProvider.notifier).refreshUser();
      ref.invalidate(walletTransactionsProvider);
    });
  }

  String _fmtAmount(double v) => NumberFormat('#,##0', 'uz').format(v);

  ({IconData icon, String label, Color color}) _meta(S s, WalletTransactionModel t) {
    return switch (t.type) {
      'topup' => (
          icon: Icons.add_card_rounded,
          label: s.txnTopup,
          color: AppColors.success,
        ),
      'subscription_charge' => (
          icon: Icons.workspace_premium_outlined,
          label: s.txnSubscription,
          color: AppColors.gold,
        ),
      'employee_seat_charge' => (
          icon: Icons.groups_2_outlined,
          label: s.txnSeat,
          color: AppColors.info,
        ),
      'refund' => (
          icon: Icons.replay_rounded,
          label: s.txnRefund,
          color: AppColors.success,
        ),
      _ => (
          icon: Icons.tune_rounded,
          label: s.txnAdjustment,
          color: AppColors.primary,
        ),
    };
  }

  /// Sana formati uchun xavfsiz locale (main.dart da initializeDateFormatting
  /// faqat uz/ru/kk/tr uchun chaqirilgan; boshqalari uz ga tushadi).
  String _dateLocale() {
    const supported = {'uz', 'ru', 'kk', 'tr'};
    final lang = Localizations.localeOf(context).languageCode;
    return supported.contains(lang) ? lang : 'uz';
  }

  String _dayLabel(S s, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return s.reportChipToday;
    if (diff == 1) return s.reportChipYesterday;
    return DateFormat('d MMMM, yyyy', _dateLocale()).format(d);
  }

  String _time(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    return d == null ? '' : DateFormat('HH:mm').format(d.toLocal());
  }

  /// Tranzaksiyalarni kun bo'yicha guruhlaydi (ro'yxat allaqachon yangidan-eskiga).
  List<MapEntry<DateTime, List<WalletTransactionModel>>> _grouped(
      List<WalletTransactionModel> txns) {
    final map = <DateTime, List<WalletTransactionModel>>{};
    for (final t in txns) {
      final parsed = t.createdAt == null ? null : DateTime.tryParse(t.createdAt!);
      final local = (parsed ?? DateTime.now()).toLocal();
      final day = DateTime(local.year, local.month, local.day);
      map.putIfAbsent(day, () => []).add(t);
    }
    return map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final txnsAsync = ref.watch(walletTransactionsProvider);
    final balance = ref.watch(
      authProvider.select((st) => st.user?.balance),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.balanceHistory),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshUser();
          ref.invalidate(walletTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 32),
          children: [
            _BalanceCard(
              balance: _fmtAmount(double.tryParse(balance ?? '0') ?? 0),
            ),
            const SizedBox(height: AppSpacing.lg),
            txnsAsync.when(
              loading: () => const SkeletonLoader(itemCount: 6, itemHeight: 64),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: ErrorRetryWidget(
                  message: e is ApiException ? e.message : e.toString(),
                  onRetry: () => ref.invalidate(walletTransactionsProvider),
                ),
              ),
              data: (txns) {
                if (txns.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 64),
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: s.noTransactions,
                      subtitle: s.noTransactionsDesc,
                    ),
                  );
                }

                final groups = _grouped(txns);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                        child: Text(
                          _dayLabel(s, group.key),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      _GroupCard(
                        children: [
                          for (final t in group.value)
                            _TxnTile(
                              meta: _meta(s, t),
                              title: (t.description?.isNotEmpty ?? false)
                                  ? t.description!
                                  : _meta(s, t).label,
                              time: _time(t.createdAt),
                              amount:
                                  '${t.isCredit ? '+' : '−'}${_fmtAmount(t.amount.abs())}',
                              isCredit: t.isCredit,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
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

// ─── Balance Card ────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final String balance;
  const _BalanceCard({required this.balance});

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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.balance,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '$balance ${s.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Group Card ──────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 64,
                color: cs.onSurface.withValues(alpha: 0.06),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ─── Transaction Tile ────────────────────────────────────────────────────────

class _TxnTile extends StatelessWidget {
  final ({IconData icon, String label, Color color}) meta;
  final String title;
  final String time;
  final String amount;
  final bool isCredit;

  const _TxnTile({
    required this.meta,
    required this.title,
    required this.time,
    required this.amount,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountColor = isCredit ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${meta.label}${time.isNotEmpty ? ' · $time' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
