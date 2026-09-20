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

/// Daromad / Xarajat / Foyda — har kun uchun yonma-yon uchta ustun.
///
/// Uchta egri chiziq bir-birining ustiga chiqib o'qib bo'lmas edi; ustunlar
/// yonma-yon turadi va taqqoslash oson. Tepadagi tugmalar legenda: bittasi
/// bosilsa o'sha ko'rsatkich ajralib, qolganlari xiralashadi. Ustun bosilsa
/// tepada aniq sana va uchala summa chiqadi. Manfiy foyda nol chizig'idan
/// pastga, qizil rangda.
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
  /// Ajratib ko'rsatilayotgan ko'rsatkich; `null` — hammasi teng.
  StatsMetric? _focus;
  int? _selected;

  static double _valueOf(StatPoint p, StatsMetric m) => switch (m) {
    StatsMetric.income => p.income,
    StatsMetric.expense => p.expense,
    StatsMetric.profit => p.profit,
  };

  double _totalOf(StatsMetric m) => switch (m) {
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

    var lo = 0.0;
    var hi = 0.0;
    for (final p in series) {
      for (final m in StatsMetric.values) {
        final v = _valueOf(p, m);
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
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

    double headValue(StatsMetric m) =>
        sel == null ? _totalOf(m) : _valueOf(series[sel], m);

    double alphaFor(StatsMetric m, int i) {
      final dimByFocus = _focus != null && _focus != m;
      final dimBySel = sel != null && sel != i;
      if (dimByFocus && dimBySel) return 0.12;
      if (dimByFocus || dimBySel) return 0.3;
      return 0.92;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Legenda / ajratish ──
        Row(
          children: [
            for (final m in StatsMetric.values) ...[
              Expanded(
                child: _MetricChip(
                  label: _label(m),
                  color: StatsPalette.of(m, dark),
                  selected: m == _focus,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _focus = _focus == m ? null : m);
                  },
                ),
              ),
              if (m != StatsMetric.values.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        // ── Sarlavha: tanlangan kun yoki davr jami, uchala summa ──
        Text(
          headDate,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final m in StatsMetric.values) ...[
              Expanded(
                child: _HeadValue(
                  color: StatsPalette.of(m, dark),
                  text: _money(headValue(m), locale),
                  dimmed: _focus != null && _focus != m,
                  negative: headValue(m) < 0,
                ),
              ),
              if (m != StatsMetric.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              alignment: BarChartAlignment.spaceBetween,
              groupsSpace: 4,
              barGroups: [
                for (var i = 0; i < series.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 1,
                    barRods: [
                      for (final m in StatsMetric.values)
                        BarChartRodData(
                          toY: _valueOf(series[i], m),
                          width: _barWidth(series.length),
                          borderRadius: BorderRadius.vertical(
                            top: _valueOf(series[i], m) >= 0
                                ? const Radius.circular(3)
                                : Radius.zero,
                            bottom: _valueOf(series[i], m) < 0
                                ? const Radius.circular(3)
                                : Radius.zero,
                          ),
                          color:
                              (_valueOf(series[i], m) < 0
                                      ? AppColors.error
                                      : StatsPalette.of(m, dark))
                                  .withValues(alpha: alphaFor(m, i)),
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

  /// Har kunda uchta ustun — kenglik kunlar soniga qarab.
  static double _barWidth(int count) {
    if (count <= 7) return 9;
    if (count <= 14) return 5;
    if (count <= 31) return 2.5;
    return 1.5;
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

/// Sarlavhadagi bitta summa — rangli nuqta bilan.
class _HeadValue extends StatelessWidget {
  const _HeadValue({
    required this.color,
    required this.text,
    required this.dimmed,
    required this.negative,
  });

  final Color color;
  final String text;
  final bool dimmed;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: negative ? AppColors.error : cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
