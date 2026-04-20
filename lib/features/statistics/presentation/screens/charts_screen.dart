import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/domain/models/daily_report_model.dart';
import '../../../home/domain/providers/daily_provider.dart';
import '../widgets/period_selector.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  DailyReportModel? _report;
  bool _isLoading = true;
  int _loadId = 0;

  PeriodType _period = PeriodType.daily;
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _from = DateTime(n.year, n.month, n.day);
    _to = _from;
    _loadReport();
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmtMoney(double v) {
    final tag = Localizations.localeOf(context).toLanguageTag();
    return NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: 0)
        .format(v);
  }

  String _moneySuffix(S s) {
    final sym = ref.read(shopProvider).selected?.currency?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    return s.currency;
  }

  String _full(double v, S s) => '${_fmtMoney(v)} ${_moneySuffix(s)}';

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
        r = await repo.getDailyReport(shop.id, _fmtDate(_from));
      } else {
        r = await repo.getRangeReport(shop.id, _fmtDate(_from), _fmtDate(_to));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
        title: Text(s.chartsScreenTitle),
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
                            _DonutSection(
                              report: _report!,
                              fmtMoney: _fmtMoney,
                              full: (v) => _full(v, s),
                              s: s,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ProductBarChart(
                              report: _report!,
                              s: s,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ExpensePieChart(
                              report: _report!,
                              full: (v) => _full(v, s),
                              s: s,
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest
            .withValues(alpha: isDark ? 0.4 : 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DonutSection extends StatelessWidget {
  const _DonutSection({
    required this.report,
    required this.fmtMoney,
    required this.full,
    required this.s,
  });

  final DailyReportModel report;
  final String Function(double) fmtMoney;
  final String Function(double) full;
  final S s;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final income = report.netSales;
    final expense = report.expenses.total;
    final profit = report.profit;
    final isPositive = profit >= 0;
    final total = income + expense + profit.abs();
    final hasData = total > 0;

    const incomeColor = AppColors.income;
    const expenseColor = AppColors.error;
    final profitColor = isPositive ? AppColors.gold : AppColors.error;

    return _ChartCard(
      title: s.chartRevenue,
      icon: Icons.donut_large_rounded,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 58,
                    startDegreeOffset: -90,
                    sections: hasData
                        ? [
                            PieChartSectionData(
                              value: income,
                              color: incomeColor,
                              radius: 32,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: expense,
                              color: expenseColor,
                              radius: 32,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: profit.abs(),
                              color: profitColor,
                              radius: 32,
                              showTitle: false,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              value: 1,
                              color:
                                  cs.onSurface.withValues(alpha: 0.08),
                              radius: 32,
                              showTitle: false,
                            ),
                          ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color:
                          isPositive ? AppColors.gold : AppColors.error,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPositive ? s.profit : s.loss,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fmtMoney(profit),
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.gold
                            : AppColors.error,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LegendItem(
                  color: incomeColor,
                  label: s.income,
                  value: full(income),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: cs.onSurface.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _LegendItem(
                  color: expenseColor,
                  label: s.expense,
                  value: full(expense),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: cs.onSurface.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _LegendItem(
                  color: profitColor,
                  label: isPositive ? s.profit : s.loss,
                  value: full(profit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductBarChart extends StatelessWidget {
  const _ProductBarChart({
    required this.report,
    required this.s,
  });

  final DailyReportModel report;
  final S s;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final products = report.productBreakdown;
    if (products.isEmpty) return const SizedBox.shrink();

    final sorted = [...products]
      ..sort((a, b) => b.totalProduced.compareTo(a.totalProduced));
    final top = sorted.take(6).toList();
    final maxVal =
        top.fold<int>(0, (m, e) => e.totalProduced > m ? e.totalProduced : m);

    return _ChartCard(
      title: s.chartProduction,
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal.toDouble() * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    cs.surface.withValues(alpha: 0.95),
                tooltipRoundedRadius: 10,
                getTooltipItem: (group, gIdx, rod, rIdx) {
                  final item = top[group.x.toInt()];
                  return BarTooltipItem(
                    '${item.name}\n${item.totalProduced} ${s.pcs}',
                    TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(),
              rightTitles:
                  const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.max || v == meta.min) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        v.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx >= top.length) return const SizedBox.shrink();
                    final name = top[idx].name;
                    final label =
                        name.length > 5 ? '${name.substring(0, 5)}…' : name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
              getDrawingHorizontalLine: (v) => FlLine(
                color: cs.onSurface.withValues(alpha: 0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(top.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].totalProduced.toDouble(),
                    width: 20,
                    color: cs.primary.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ExpensePieChart extends StatelessWidget {
  const _ExpensePieChart({
    required this.report,
    required this.full,
    required this.s,
  });

  final DailyReportModel report;
  final String Function(double) full;
  final S s;

  static const _palette = [
    AppColors.primary,
    AppColors.gold,
    AppColors.error,
    AppColors.info,
    AppColors.warning,
    AppColors.income,
    AppColors.primaryLight,
    AppColors.goldLight,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expenses = report.expenses;
    final entries = <_ExpenseEntry>[];

    if (expenses.ingredientCost > 0) {
      entries.add(_ExpenseEntry(s.internalIngredients, expenses.ingredientCost));
    }
    if (expenses.external > 0) {
      entries.add(_ExpenseEntry(s.external, expenses.external));
    }
    for (final e in expenses.byCategory.entries) {
      if (e.value > 0) entries.add(_ExpenseEntry(e.key, e.value));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return _ChartCard(
      title: s.chartExpenses,
      icon: Icons.pie_chart_outline_rounded,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                startDegreeOffset: -90,
                sections: List.generate(entries.length, (i) {
                  return PieChartSectionData(
                    value: entries[i].amount,
                    color: _palette[i % _palette.length],
                    radius: 28,
                    showTitle: false,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.label}: ${full(e.amount)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEntry {
  const _ExpenseEntry(this.label, this.amount);
  final String label;
  final double amount;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
