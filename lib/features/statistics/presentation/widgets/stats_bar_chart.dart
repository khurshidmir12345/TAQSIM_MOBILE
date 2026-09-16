import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/statistics_model.dart';

/// Qaysi ko'rsatkich chizilayotgani.
enum StatsMetric { income, expense, profit }

/// Seriya ranglari — yorug' va qorong'i rejim uchun alohida.
class StatsPalette {
  const StatsPalette._();

  static Color income(bool dark) =>
      dark ? const Color(0xFF4C9350) : const Color(0xFF2E7D32);

  static Color expense(bool dark) =>
      dark ? const Color(0xFFC27B2E) : const Color(0xFFF57C00);

  static Color profit(bool dark) =>
      dark ? const Color(0xFF3B82C4) : const Color(0xFF1565C0);

  static Color of(StatsMetric m, bool dark) => switch (m) {
    StatsMetric.income => income(dark),
    StatsMetric.expense => expense(dark),
    StatsMetric.profit => profit(dark),
  };
}

/// Bitta ko'rsatkich — ustunli grafik.
///
/// Uchta chiziq bir-birining ustiga chiqib o'qib bo'lmas edi; endi
/// foydalanuvchi ko'rsatkichni tanlaydi (Daromad / Xarajat / Foyda), har kun
/// bitta ustun, ustun bosilsa tepada aniq sana va summa chiqadi. Manfiy foyda
/// nol chizig'idan pastga, qizil rangda.
class StatsBarChart extends StatefulWidget {
  const StatsBarChart({
    super.key,
    required this.series,
    required this.totals,
    this.isMonthly = false,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.profitLabel,
    required this.periodTotalLabel,
    required this.hint,
    required this.moneySuffix,
  });

  final List<StatPoint> series;
  final StatTotals totals;

  /// Nuqtalar oylarga guruhlanganmi — o'q sanalari shunga qarab yoziladi.
  final bool isMonthly;

  final String incomeLabel;
  final String expenseLabel;
  final String profitLabel;
  final String periodTotalLabel;
  final String hint;
  final String moneySuffix;

  @override
  State<StatsBarChart> createState() => _StatsBarChartState();
}

class _StatsBarChartState extends State<StatsBarChart> {
  StatsMetric _metric = StatsMetric.income;
  int? _selected;

  double _value(StatPoint p) => switch (_metric) {
    StatsMetric.income => p.income,
    StatsMetric.expense => p.expense,
    StatsMetric.profit => p.profit,
  };

  double _total() => switch (_metric) {
    StatsMetric.income => widget.totals.income,
    StatsMetric.expense => widget.totals.expense,
    StatsMetric.profit => widget.totals.profit,
  };

  String _label(StatsMetric m) => switch (m) {
    StatsMetric.income => widget.incomeLabel,
    StatsMetric.expense => widget.expenseLabel,
    StatsMetric.profit => widget.profitLabel,
  };

  String _money(double v, String locale) {
    final n = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 0,
    ).format(v.abs());
    return '${v < 0 ? '−' : ''}$n ${widget.moneySuffix}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final series = widget.series;

    if (series.isEmpty) return const SizedBox.shrink();

    final color = StatsPalette.of(_metric, dark);
    final values = series.map(_value).toList();

    var lo = 0.0;
    var hi = 0.0;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    if (hi == lo) hi = lo + 1;
    final maxY = hi + (hi - lo) * 0.12;
    final minY = lo < 0 ? lo - (hi - lo) * 0.12 : 0.0;

    final sel = _selected != null && _selected! < series.length
        ? _selected
        : null;
    final headDate = sel == null
        ? widget.periodTotalLabel
        : DateFormat(
            widget.isMonthly ? 'LLLL yyyy' : 'd MMMM, EEEE',
            locale,
          ).format(series[sel].date);
    final headValue = sel == null ? _total() : values[sel];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ko'rsatkich tanlovi ──
        Row(
          children: [
            for (final m in StatsMetric.values) ...[
              Expanded(
                child: _MetricChip(
                  label: _label(m),
                  color: StatsPalette.of(m, dark),
                  selected: m == _metric,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _metric = m;
                      _selected = null;
                    });
                  },
                ),
              ),
              if (m != StatsMetric.values.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        // ── Sarlavha: tanlangan kun yoki davr jami ──
        Text(
          headDate,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _money(headValue, locale),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: headValue < 0 ? AppColors.error : cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              alignment: BarChartAlignment.spaceBetween,
              groupsSpace: 2,
              barGroups: [
                for (var i = 0; i < values.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: _barWidth(values.length),
                        borderRadius: BorderRadius.vertical(
                          top: values[i] >= 0
                              ? const Radius.circular(4)
                              : Radius.zero,
                          bottom: values[i] < 0
                              ? const Radius.circular(4)
                              : Radius.zero,
                        ),
                        color: values[i] < 0
                            ? AppColors.error.withValues(
                                alpha: sel == null || sel == i ? 0.9 : 0.35,
                              )
                            : color.withValues(
                                alpha: sel == null || sel == i ? 0.9 : 0.3,
                              ),
                      ),
                    ],
                  ),
              ],
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: cs.onSurface.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ],
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: _gridInterval(minY, maxY),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _gridInterval(minY, maxY),
                    getTitlesWidget: (v, meta) {
                      if (v == meta.max || v == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          _compact(v),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, meta) {
                      final i = v.round();
                      if (i < 0 || i >= series.length) {
                        return const SizedBox.shrink();
                      }
                      final step = _labelStep(series.length);
                      if (i % step != 0 && i != series.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat(
                            widget.isMonthly ? 'LLL' : 'd MMM',
                            locale,
                          ).format(series[i].date),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: i == sel
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: cs.onSurface.withValues(
                              alpha: i == sel ? 0.9 : 0.45,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;
                  final idx = response?.spot?.touchedBarGroupIndex;
                  if (idx == null) return;
                  if (idx != _selected) HapticFeedback.selectionClick();
                  setState(() => _selected = idx == _selected ? null : idx);
                },
              ),
            ),
            duration: const Duration(milliseconds: 220),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.hint,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  static double _barWidth(int count) {
    if (count <= 7) return 22;
    if (count <= 14) return 14;
    if (count <= 31) return 7;
    return 4;
  }

  static int _labelStep(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    return (count / 5).ceil();
  }

  /// Yumaloq o'q qadami: 1, 2, 5 × 10^n — 4–6 ta chiziq chiqadi.
  static double _gridInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 0) return 1;
    final raw = range / 5;
    final mag = _pow10(raw.abs().toStringAsFixed(0).length - 1);
    for (final k in [1, 2, 5, 10]) {
      final step = k * mag;
      if (step >= raw) return step.toDouble();
    }
    return (10 * mag).toDouble();
  }

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  /// O'q yorlig'i: 1 250 000 → 1,2M
  static String _compact(double v) {
    final a = v.abs();
    final sign = v < 0 ? '−' : '';
    if (a >= 1000000) {
      return '$sign${(a / 1000000).toStringAsFixed(a >= 10000000 ? 0 : 1)}M';
    }
    if (a >= 1000) {
      return '$sign${(a / 1000).toStringAsFixed(a >= 10000 ? 0 : 1)}K';
    }
    return v.toStringAsFixed(0);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? color
          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!selected) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : cs.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
