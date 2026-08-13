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
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../../core/widgets/time_badge.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/daily_report_model.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/providers/daily_provider.dart';
import '../widgets/expense_actions.dart';

/// Kassa bo'limi — davr bo'yicha tushum/xarajat/sof natija + bugungi
/// xarajatlar ro'yxati.
///
/// Tushum (income) = netto sotuv (`report.netSales`),
/// Xarajat (expense) = umumiy xarajatlar (`report.expenses.total`),
/// Sof (net) = `report.profit`.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ExpensesScreenState createState() => ExpensesScreenState();
}

enum _CashPeriod { all, month, day }

class ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  _CashPeriod _period = _CashPeriod.day;

  DailyReportModel? _report;
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

  ({DateTime from, DateTime to}) _periodRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      _CashPeriod.day => (from: today, to: today),
      _CashPeriod.month => (from: DateTime(now.year, now.month), to: today),
      // "Barchasi" — do'kon ochilgan kundan buyon. Sana noma'lum bo'lsa
      // ataylab uzoq o'tmish olinadi: ortiqcha oraliq natijani buzmaydi.
      _CashPeriod.all => (from: _shopStart(), to: today),
    };
  }

  DateTime _shopStart() {
    final raw = ref.read(shopProvider).selected?.createdAt;
    final parsed = raw == null ? null : DateTime.tryParse(raw);

    return parsed == null ? DateTime(2020) : DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _ymd(DateTime d) => d.toIso8601String().split('T').first;

  Future<void> _load() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _report = null;
        _expenses = [];
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final range = _periodRange();
    final repo = ref.read(dailyRepositoryProvider);
    final todayStr = _ymd(DateTime.now());
    final locale = expenseApiLocale(context);

    try {
      final report = _period == _CashPeriod.day
          ? await repo.getDailyReport(shop.id, todayStr)
          : await repo.getRangeReport(shop.id, _ymd(range.from), _ymd(range.to));

      final expenses = await repo.getExpenses(
        shop.id,
        todayStr,
        locale: locale,
      );

      if (!mounted) return;
      setState(() {
        _report = report;
        _expenses = expenses;
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

  Future<void> _openCreate() async {
    HapticFeedback.selectionClick();
    await context.push('/expense-create');
    if (mounted) _load();
  }

  Future<void> _openActions(ExpenseModel e) async {
    final changed = await showExpenseActions(context, ref: ref, expense: e);
    if (changed && mounted) _load();
  }

  void _setPeriod(_CashPeriod p) {
    if (p == _period) return;
    setState(() => _period = p);
    _load();
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
                s.cashbox,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
              child: SegmentedTabs<_CashPeriod>(
                tabs: _CashPeriod.values,
                labelOf: (p) => switch (p) {
                  _CashPeriod.all => s.periodAll,
                  _CashPeriod.month => s.monthly,
                  _CashPeriod.day => s.daily,
                },
                selected: _period,
                onChanged: _setPeriod,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: AppLoading())
                  : _error != null
                      ? ErrorRetryWidget(message: _error!, onRetry: _load)
                      : _CashboxBody(
                          report: _report,
                          expenses: _expenses,
                          fmt: _fmtMoney,
                          currency: s.currency,
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

class _CashboxBody extends StatelessWidget {
  const _CashboxBody({
    required this.report,
    required this.expenses,
    required this.fmt,
    required this.currency,
    required this.pad,
    required this.cs,
    required this.isDark,
    required this.onRefresh,
    required this.onTapExpense,
  });

  final DailyReportModel? report;
  final List<ExpenseModel> expenses;
  final String Function(double) fmt;
  final String currency;
  final double pad;
  final ColorScheme cs;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final ValueChanged<ExpenseModel> onTapExpense;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final income = report?.netSales ?? 0;
    final expense = report?.expenses.total ?? 0;
    final net = report?.profit ?? (income - expense);

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, AppSpacing.sm, pad, 0),
              child: _CashSummary(
                income: income,
                expense: expense,
                net: net,
                currency: currency,
                fmt: fmt,
                cs: cs,
                isDark: isDark,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, AppSpacing.lg, pad, AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Text(
                    s.expenses,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    s.daily,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (expenses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 32),
                child: EmptyStateWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: s.noExpenseToday,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 120),
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

class _CashSummary extends StatelessWidget {
  const _CashSummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.currency,
    required this.fmt,
    required this.cs,
    required this.isDark,
  });

  final double income;
  final double expense;
  final double net;
  final String currency;
  final String Function(double) fmt;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final netColor = net >= 0 ? AppColors.success : AppColors.error;
    final border = cs.outline.withValues(alpha: isDark ? 0.35 : 0.18);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
            cs.tertiary.withValues(alpha: isDark ? 0.12 : 0.06),
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
            s.cashNet,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${fmt(net)} $currency',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: netColor,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: s.income,
                  value: '${fmt(income)} $currency',
                  color: AppColors.success,
                  icon: Icons.south_west_rounded,
                  cs: cs,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  label: s.expense,
                  value: '${fmt(expense)} $currency',
                  color: AppColors.error,
                  icon: Icons.north_east_rounded,
                  cs: cs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.cs,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
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
