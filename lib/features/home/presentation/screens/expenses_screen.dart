import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/expense_api_locale.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/time_badge.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/providers/daily_provider.dart';
import '../widgets/expense_actions.dart';

/// Bugungi tashqi xarajatlar uchun mustaqil ekran.
///
/// Avval Tarix ichidagi `Kassa` tab edi — endi alohida bo'lim. Mantiq aynan
/// avvalgidek (sana = bugun, refresh-on-mount, FAB), faqat alohida sahifaga
/// ko'chirilib zamonaviy header qo'shildi.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ExpensesScreenState createState() => ExpensesScreenState();
}

class ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  List<ExpenseModel> _expenses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  /// Tashqaridan refresh qilish uchun (Shell tab tap'da chaqiriladi).
  void refresh() => _load();

  Future<void> _load() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _expenses = [];
      });
      return;
    }
    final date = DateTime.now().toIso8601String().split('T').first;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await ref.read(dailyRepositoryProvider).getExpenses(
            shop.id,
            date,
            locale: expenseApiLocale(context),
          );
      if (!mounted) return;
      setState(() {
        _expenses = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _fmtMoney(double n) {
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

  Future<void> _openCreate() async {
    HapticFeedback.selectionClick();
    await context.push('/expense-create');
    if (mounted) _load();
  }

  Future<void> _openActions(ExpenseModel e) async {
    final changed = await showExpenseActions(
      context,
      ref: ref,
      expense: e,
    );
    if (changed && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = Responsive.horizontalPadding(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 4),
              child: Text(
                s.expenses,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: AppLoading())
                  : _error != null
                      ? ErrorRetryWidget(message: _error!, onRetry: _load)
                      : _ExpensesBody(
                          expenses: _expenses,
                          total: _total,
                          fmt: _fmtMoney,
                          currency: s.currency,
                          subtitle: s.cashRegister,
                          pad: pad,
                          cs: cs,
                          isDark: isDark,
                          onRefresh: _load,
                          onTapExpense: _openActions,
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(s.addExpense),
            ),
    );
  }
}

class _ExpensesBody extends StatelessWidget {
  const _ExpensesBody({
    required this.expenses,
    required this.total,
    required this.fmt,
    required this.currency,
    required this.subtitle,
    required this.pad,
    required this.cs,
    required this.isDark,
    required this.onRefresh,
    required this.onTapExpense,
  });

  final List<ExpenseModel> expenses;
  final double total;
  final String Function(double) fmt;
  final String currency;
  final String subtitle;
  final double pad;
  final ColorScheme cs;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final ValueChanged<ExpenseModel> onTapExpense;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, AppSpacing.sm, pad, 0),
              child: _ExpensesSummaryHero(
                total: total,
                currency: currency,
                fmt: fmt,
                cs: cs,
                isDark: isDark,
                subtitle: subtitle,
              ),
            ),
          ),
          if (expenses.isEmpty)
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
                itemCount: expenses.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final e = expenses[i];
                  return _ExpenseTile(
                    expense: e,
                    fmt: fmt,
                    currency: currency,
                    onTap: () => onTapExpense(e),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpensesSummaryHero extends StatelessWidget {
  const _ExpensesSummaryHero({
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
    required this.expense,
    required this.fmt,
    required this.currency,
    this.onTap,
  });

  final ExpenseModel expense;
  final String Function(double) fmt;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = formatTimeHm(expense.createdAt);
    final desc = expense.description?.trim();

    return Material(
      color: cs.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.35 : 0.65,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: InkWell(
        onTap: onTap,
        onLongPress: onTap,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expense.displayCategoryLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(width: 8),
                          TimeBadge(time: time, compact: true),
                        ],
                      ],
                    ),
                    if (desc != null && desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          desc,
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
                '${fmt(expense.amount)} $currency',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
