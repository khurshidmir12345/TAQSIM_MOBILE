import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/domain/models/daily_report_model.dart';
import '../../../home/domain/providers/daily_provider.dart';
import '../widgets/period_selector.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DailyReportModel? _report;
  bool _isLoading = true;
  int _loadId = 0;

  PeriodType _period = PeriodType.daily;
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = _from;
    _loadReport();
  }

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _moneySuffix(S s, WidgetRef ref) {
    final sym = ref.read(shopProvider).selected?.currency?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    return s.currency;
  }

  String _fmtMoney(BuildContext context, double v, WidgetRef ref) {
    final tag = Localizations.localeOf(context).toLanguageTag();
    final n = NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: 0)
        .format(v);
    return '$n ${_moneySuffix(S.of(context), ref)}';
  }

  String _periodLabel(BuildContext context) {
    final loc = Localizations.localeOf(context).toLanguageTag();
    switch (_period) {
      case PeriodType.daily:
        return DateFormat.yMMMEd(loc).format(_from);
      case PeriodType.weekly:
        return '${DateFormat.MMMd(loc).format(_from)} — ${DateFormat.yMMMd(loc).format(_to)}';
      case PeriodType.monthly:
        return DateFormat.yMMMM(loc).format(_from);
    }
  }

  void _onPeriodChanged(PeriodType period, DateTime from, DateTime to) {
    if (_period == period && _from == from && _to == to) return;
    _period = period;
    _from = from;
    _to = to;
    _loadReport();
  }

  Future<void> _loadReport() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null) return;

    final id = ++_loadId;
    setState(() => _isLoading = true);
    final repo = ref.read(dailyRepositoryProvider);

    try {
      final DailyReportModel r;
      if (_period == PeriodType.daily) {
        r = await repo.getDailyReport(shop.id, _iso(_from));
      } else {
        r = await repo.getRangeReport(shop.id, _iso(_from), _iso(_to));
      }
      if (mounted && _loadId == id) {
        setState(() {
          _report = r;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _loadId == id) {
        setState(() => _isLoading = false);
        final msg = e is ApiException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(s.reportScreenTitle),
        actions: [
          IconButton(
            tooltip: s.charts,
            icon: const Icon(Icons.insert_chart_outlined_rounded),
            onPressed: () => context.push('/charts'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelector(onChanged: _onPeriodChanged),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
            child: Text(
              _periodLabel(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoading())
                : _report == null
                    ? Center(
                        child: Text(
                          s.noData,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadReport,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, 32),
                          children: [
                            _ReportKpiBlock(
                              report: _report!,
                              fmt: (v) => _fmtMoney(context, v, ref),
                              s: s,
                              cs: cs,
                            ),
                            SizedBox(height: AppSpacing.md),
                            _ReportExpandables(
                              report: _report!,
                              fmt: (v) => _fmtMoney(context, v, ref),
                              s: s,
                              cs: cs,
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ReportKpiBlock extends StatelessWidget {
  const _ReportKpiBlock({
    required this.report,
    required this.fmt,
    required this.s,
    required this.cs,
  });

  final DailyReportModel report;
  final String Function(double) fmt;
  final S s;
  final ColorScheme cs;

  double _gross() =>
      report.sales.grossAmount ??
      (report.netSales + report.returns.totalAmount);

  @override
  Widget build(BuildContext context) {
    final gross = _gross();
    final profit = report.profit;
    final profitPos = profit >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.payments_outlined,
                label: s.netIncome,
                value: fmt(report.netSales),
                tone: AppColors.income,
                cs: cs,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                icon: Icons.undo_rounded,
                label: s.returnAmount,
                value: fmt(report.returns.totalAmount),
                tone: AppColors.error,
                cs: cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.receipt_long_outlined,
                label: s.expense,
                value: fmt(report.expenses.total),
                tone: cs.primary,
                cs: cs,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                icon: profitPos
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label: profitPos ? s.profit : s.loss,
                value: fmt(profit),
                tone: profitPos ? AppColors.success : AppColors.error,
                cs: cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest
                .withValues(alpha: isDark ? 0.35 : 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: cs.primary.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${s.reportGrossRevenue}: ${fmt(gross)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: isDark ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tone.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: tone),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportExpandables extends StatelessWidget {
  const _ReportExpandables({
    required this.report,
    required this.fmt,
    required this.s,
    required this.cs,
  });

  final DailyReportModel report;
  final String Function(double) fmt;
  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final returns = report.returnsByCategory;
    final products = report.productBreakdown;
    final retSum = returns.fold<double>(0, (a, b) => a + b.totalAmount);
    final productNetSum =
        products.fold<double>(0, (a, b) => a + b.netRevenue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoundExpansion(
          cs: cs,
          leading: Icon(Icons.undo_rounded, color: AppColors.error, size: 22),
          title: s.reportSectionReturnsByType,
          subtitle:
              returns.isEmpty ? s.reportEmptyReturns : fmt(retSum),
          initiallyExpanded: returns.isNotEmpty && returns.length <= 4,
          child: returns.isEmpty
              ? const SizedBox.shrink()
              : _ReturnsList(
                  items: returns,
                  fmt: fmt,
                  s: s,
                  cs: cs,
                ),
        ),
        const SizedBox(height: 10),
        _RoundExpansion(
          cs: cs,
          leading:
              Icon(Icons.inventory_2_outlined, color: cs.primary, size: 22),
          title: s.reportSectionProducts,
          subtitle: products.isEmpty
              ? s.reportEmptyProducts
              : fmt(productNetSum),
          initiallyExpanded: true,
          child: products.isEmpty
              ? const SizedBox.shrink()
              : _ProductRows(
                  items: products,
                  fmt: fmt,
                  s: s,
                  cs: cs,
                ),
        ),
        const SizedBox(height: 10),
        _RoundExpansion(
          cs: cs,
          leading:
              Icon(Icons.savings_outlined, color: cs.tertiary, size: 22),
          title: s.expenses,
          subtitle: fmt(report.expenses.total),
          initiallyExpanded: false,
          child: _ExpenseInner(
            report: report,
            fmt: fmt,
            s: s,
            cs: cs,
          ),
        ),
        const SizedBox(height: 10),
        _RoundExpansion(
          cs: cs,
          leading:
              Icon(Icons.analytics_outlined, color: cs.outline, size: 22),
          title: s.reportSectionSummary,
          subtitle: fmt(report.netSales),
          initiallyExpanded: false,
          child: _MoreStats(
            report: report,
            fmt: fmt,
            s: s,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _RoundExpansion extends StatelessWidget {
  const _RoundExpansion({
    required this.cs,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.initiallyExpanded,
    required this.child,
  });

  final ColorScheme cs;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool initiallyExpanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cs.surfaceContainerHighest
          .withValues(alpha: isDark ? 0.4 : 0.55),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: leading,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _ReturnsList extends StatelessWidget {
  const _ReturnsList({
    required this.items,
    required this.fmt,
    required this.s,
    required this.cs,
  });

  final List<ReportReturnByCategory> items;
  final String Function(double) fmt;
  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            s.reportExpandTypesCount(items.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...items.map((e) {
          final name = e.name.isEmpty ? s.unknown : e.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.undo_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.quantity} ${s.pcs}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: cs.onSurface
                                    .withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fmt(e.totalAmount),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ProductRows extends StatelessWidget {
  const _ProductRows({
    required this.items,
    required this.fmt,
    required this.s,
    required this.cs,
  });

  final List<ReportProductBreakdown> items;
  final String Function(double) fmt;
  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            s.reportExpandProductsCount(items.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...items.map((e) {
          final profitPos = e.profit >= 0;
          final letter = e.name.isNotEmpty
              ? e.name.substring(0, 1).toUpperCase()
              : '?';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: cs.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    _showProductDetail(context, e, fmt, s, cs),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name.isEmpty ? s.unknown : e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${fmt(e.netRevenue)} · ${e.totalProduced} ${s.pcs}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fmt(e.profit),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: profitPos
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showProductDetail(
    BuildContext context,
    ReportProductBreakdown e,
    String Function(double) fmt,
    S s,
    ColorScheme cs,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                e.name.isEmpty ? s.unknown : e.name,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              _sheetRow(ctx, s.reportProductProduced,
                  '${e.totalProduced} ${s.pcs}', cs),
              _sheetRow(
                  ctx, s.reportGrossRevenue, fmt(e.grossRevenue), cs),
              _sheetRow(ctx, s.internalIngredients,
                  fmt(e.ingredientCost), cs),
              _sheetRow(
                ctx,
                s.returns,
                '${e.returnsQuantity} ${s.pcs} · ${fmt(e.returnsAmount)}',
                cs,
              ),
              _sheetRow(ctx, s.netIncome, fmt(e.netRevenue), cs),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.profit,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    fmt(e.profit),
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: e.profit >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetRow(
      BuildContext context, String a, String b, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              a,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              b,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseInner extends StatelessWidget {
  const _ExpenseInner({
    required this.report,
    required this.fmt,
    required this.s,
    required this.cs,
  });

  final DailyReportModel report;
  final String Function(double) fmt;
  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final by = report.expenses.byCategory;
    return Column(
      children: [
        _row(context, s.internalIngredients,
            fmt(report.expenses.ingredientCost)),
        _row(context, s.external, fmt(report.expenses.external)),
        ...by.entries.map((e) => _row(context, e.key, fmt(e.value))),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1),
        ),
        _row(context, s.total, fmt(report.expenses.total), bold: true),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String v,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            v,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoreStats extends StatelessWidget {
  const _MoreStats({
    required this.report,
    required this.fmt,
    required this.s,
    required this.cs,
  });

  final DailyReportModel report;
  final String Function(double) fmt;
  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final gross = report.sales.grossAmount ??
        (report.netSales + report.returns.totalAmount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${report.production.totalBread} ${s.pcs} · ${report.production.count}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        _row(context, s.reportGrossRevenue, fmt(gross)),
        _row(context, s.totalProduced,
            '${report.production.totalBread} ${s.pcs}'),
        _row(context, s.returns,
            '${report.returns.totalQuantity} ${s.pcs} · ${fmt(report.returns.totalAmount)}'),
        _row(context, s.soldAuto,
            '${report.sales.totalQuantity} ${s.pcs}'),
        _row(context, s.reportProductionRecords,
            '${report.production.count}'),
      ],
    );
  }

  Widget _row(BuildContext context, String a, String b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              a,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            b,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
