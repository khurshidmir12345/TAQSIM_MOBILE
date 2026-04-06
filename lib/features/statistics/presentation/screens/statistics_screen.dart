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

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DailyReportModel? _report;
  bool _isLoading = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _selectedDate = DateTime(n.year, n.month, n.day);
    _loadReport();
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmtMoney(dynamic v) {
    final num = double.tryParse(v?.toString() ?? '0') ?? 0;
    return NumberFormat('#,##0', 'uz').format(num);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _selectDayChip(DateTime day) {
    setState(() {
      _selectedDate = DateTime(day.year, day.month, day.day);
    });
    _loadReport();
  }

  Future<void> _loadReport() async {
    final shopState = ref.read(shopProvider);
    if (shopState.selected == null) return;
    final shopId = shopState.selected!.id;
    final repo = ref.read(dailyRepositoryProvider);

    setState(() => _isLoading = true);

    try {
      final result =
          await repo.getDailyReport(shopId, _fmtDate(_selectedDate));

      if (mounted) {
        setState(() {
          _report = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _dayTitle(S s) {
    final now = _selectedDate;
    return DateFormat('d MMMM, yyyy', 'uz').format(now);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);
    final s = S.of(context);
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(s.statistics),
        actions: [
          IconButton(
            tooltip: s.reportPickSingleDate,
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 4, pad, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatDayChip(
                    label: s.reportChipToday,
                    selected: _sameDay(_selectedDate, today0),
                    onTap: () => _selectDayChip(today0),
                    cs: cs,
                  ),
                  _StatDayChip(
                    label: s.reportChipYesterday,
                    selected: _sameDay(
                      _selectedDate,
                      today0.subtract(const Duration(days: 1)),
                    ),
                    onTap: () => _selectDayChip(
                      today0.subtract(const Duration(days: 1)),
                    ),
                    cs: cs,
                  ),
                  for (int i = 2; i <= 7; i++)
                    _StatDayChip(
                      label: DateFormat('dd.MM').format(
                        today0.subtract(Duration(days: i)),
                      ),
                      selected: _sameDay(
                        _selectedDate,
                        today0.subtract(Duration(days: i)),
                      ),
                      onTap: () => _selectDayChip(
                        today0.subtract(Duration(days: i)),
                      ),
                      cs: cs,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 6, pad, 8),
            child: Text(
              _dayTitle(s),
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
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReport,
                        color: AppColors.primary,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, 32),
                          children: [
                            _buildDonutChart(s),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(S s) {
    final cs = Theme.of(context).colorScheme;

    final income = _report?.netSales ?? 0.0;
    final expense = _report?.expenses.total ?? 0.0;
    final profit = _report?.profit ?? 0.0;
    final isPositive = profit >= 0;

    final total = income + expense + profit.abs();
    final hasData = total > 0;

    const incomeColor = AppColors.income;
    const expenseColor = AppColors.error;
    final profitColor = isPositive ? AppColors.gold : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
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
                    centerSpaceRadius: 60,
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
                              color: cs.onSurface.withValues(alpha: 0.08),
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
                      color: isPositive ? AppColors.gold : AppColors.error,
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
                      _fmtMoney(profit),
                      style: TextStyle(
                        color: isPositive ? AppColors.gold : AppColors.error,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      s.currency,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.35),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: _ChartLegendItem(
                    color: incomeColor,
                    label: s.income,
                    value: '${_fmtMoney(income)} ${s.currency}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _ChartLegendItem(
                    color: expenseColor,
                    label: s.expense,
                    value: '${_fmtMoney(expense)} ${s.currency}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _ChartLegendItem(
                    color: profitColor,
                    label: isPositive ? s.profit : s.loss,
                    value: '${_fmtMoney(profit)} ${s.currency}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDayChip extends StatelessWidget {
  const _StatDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: selected ? cs.onPrimaryContainer : cs.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
