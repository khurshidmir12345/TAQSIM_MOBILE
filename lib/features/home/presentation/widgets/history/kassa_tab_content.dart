import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/expense_api_locale.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/l10n/translations.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_loading.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../../../../../core/widgets/error_retry_widget.dart';
import '../../../../auth/domain/providers/auth_provider.dart';
import '../../../domain/models/expense_model.dart';
import '../../../domain/providers/daily_provider.dart';

/// Bugungi kassa xarajatlari — tarix ichidagi «Kassa» bo‘limi.
class KassaTabContent extends ConsumerStatefulWidget {
  const KassaTabContent({super.key});

  @override
  KassaTabContentState createState() => KassaTabContentState();
}

class KassaTabContentState extends ConsumerState<KassaTabContent> {
  List<ExpenseModel> _expenses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void refresh() => _load();

  Future<void> _load() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null) {
      setState(() {
        _loading = false;
        _expenses = [];
      });
      return;
    }
    final date = DateTime.now().toIso8601String().split('T').first;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(dailyRepositoryProvider).getExpenses(
            shop.id,
            date,
            locale: expenseApiLocale(context),
          );
      if (mounted) {
        setState(() {
          _expenses = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _fmtMoney(BuildContext context, double n) {
    final l = Localizations.localeOf(context);
    final tag = l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
    return NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: 0)
        .format(n);
  }

  double get _total {
    var sum = 0.0;
    for (final e in _expenses) {
      sum += e.amount;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = Responsive.horizontalPadding(context);

    if (_loading) {
      return const Center(child: AppLoading());
    }
    if (_error != null) {
      return ErrorRetryWidget(message: _error!, onRetry: _load);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
          color: cs.primary,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, 0),
                  child: _KassaSummaryHero(
                    total: _total,
                    currency: s.currency,
                    fmt: (v) => _fmtMoney(context, v),
                    cs: cs,
                    isDark: isDark,
                    subtitle: s.historyTabCash,
                  ),
                ),
              ),
              if (_expenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.account_balance_wallet_outlined,
                    title: s.noExpenseToday,
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    AppSpacing.lg,
                    pad,
                    120,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _expenses.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final e = _expenses[i];
                      return _ExpenseTile(
                        category: e.displayCategoryLabel,
                        amount: e.amount,
                        description: e.description,
                        fmt: (v) => _fmtMoney(context, v),
                        currency: s.currency,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        ),
        Positioned(
          right: pad,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/expense-create').then((_) => _load()),
            icon: const Icon(Icons.add_rounded),
            label: Text(s.addExpense),
          ),
        ),
      ],
    );
  }
}

class _KassaSummaryHero extends StatelessWidget {
  const _KassaSummaryHero({
    required this.total,
    required this.currency,
    required this.fmt,
    required this.cs,
    required this.isDark,
    required this.subtitle,
  });

  final double total;
  final String currency;
  final String Function(double) fmt;
  final ColorScheme cs;
  final bool isDark;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final border = cs.outline.withValues(alpha: isDark ? 0.35 : 0.18);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            cs.tertiary.withValues(alpha: isDark ? 0.14 : 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 4),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${fmt(total)} $currency',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context).daily,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.category,
    required this.amount,
    this.description,
    required this.fmt,
    required this.currency,
  });

  final String category;
  final double amount;
  final String? description;
  final String Function(double) fmt;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cs.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.35 : 0.65,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (description != null && description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          description!.trim(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.5),
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${fmt(amount)} $currency',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
              ),
            ],
          ),
        ),
    );
  }
}
