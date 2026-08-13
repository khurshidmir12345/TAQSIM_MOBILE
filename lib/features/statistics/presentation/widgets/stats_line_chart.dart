import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/statistics_model.dart';

/// Daromad / foyda / xarajat — bitta grafikda, kunlar bo'yicha.
///
/// Ranglar tekshiruvdan o'tgan: qizil–yashil juftligi ataylab ishlatilmagan,
/// chunki rang ko'rmaslikda ular ajralmaydi. Har uchala seriya yorug' va
/// qorong'i rejim uchun alohida tanlangan.
class StatsPalette {
  const StatsPalette._();

  // Yorug' rejim
  static const Color incomeLight = Color(0xFF2E7D32);
  static const Color profitLight = Color(0xFF1565C0);
  static const Color expenseLight = Color(0xFFF57C00);

  // Qorong'i rejim — avtomatik ochirilgan emas, alohida tanlangan qadamlar
  static const Color incomeDark = Color(0xFF4C9350);
  static const Color profitDark = Color(0xFF3B82C4);
  static const Color expenseDark = Color(0xFFC27B2E);

  static Color income(bool dark) => dark ? incomeDark : incomeLight;

  static Color profit(bool dark) => dark ? profitDark : profitLight;

  static Color expense(bool dark) => dark ? expenseDark : expenseLight;
}

class StatsLineChart extends StatelessWidget {
  const StatsLineChart({
    super.key,
    required this.series,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.profitLabel,
    required this.moneySuffix,
  });

  final List<StatPoint> series;
  final String incomeLabel;
  final String expenseLabel;
  final String profitLabel;
  final String moneySuffix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toLanguageTag();

    if (series.isEmpty) return const SizedBox.shrink();

    final incomeColor = StatsPalette.income(dark);
    final profitColor = StatsPalette.profit(dark);
    final expenseColor = StatsPalette.expense(dark);

    double lo = 0;
    double hi = 0;

    for (final p in series) {
      for (final v in [p.income, p.expense, p.profit]) {
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
    }

    // Tekis chiziq bo'lsa ham grafik ko'rinsin.
    if (hi == lo) hi = lo + 1;
    final pad = (hi - lo) * 0.12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uch seriya — legenda majburiy, rang yagona belgi bo'lib qolmasin.
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendDot(color: incomeColor, label: incomeLabel),
            _LegendDot(color: profitColor, label: profitLabel),
            _LegendDot(color: expenseColor, label: expenseLabel),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: LineChart(
            LineChartData(
              minY: lo - pad,
              maxY: hi + pad,
              minX: 0,
              maxX: (series.length - 1).toDouble(),
              clipData: const FlClipData.all(),
              lineBarsData: [
                _bar(series.map((p) => p.income).toList(), incomeColor),
                _bar(series.map((p) => p.profit).toList(), profitColor),
                _bar(series.map((p) => p.expense).toList(), expenseColor),
              ],
              // Foyda manfiy bo'lishi mumkin — nol chizig'i mo'ljal beradi.
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: cs.onSurface.withValues(alpha: 0.25),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ],
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
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
                    reservedSize: 44,
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
                    reservedSize: 26,
                    interval: _labelInterval(series.length),
                    getTitlesWidget: (v, meta) {
                      final i = v.round();

                      if (i < 0 || i >= series.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('d MMM', locale).format(series[i].date),
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
              ),
              lineTouchData: LineTouchData(
                getTouchedSpotIndicator: (bar, indexes) => indexes
                    .map(
                      (_) => TouchedSpotIndicatorData(
                        FlLine(
                          color: cs.onSurface.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        ),
                        FlDotData(
                          getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                            radius: 4,
                            color: bar.color ?? cs.primary,
                            // Ustma-ust tushgan nuqtalar ajralib tursin.
                            strokeWidth: 2,
                            strokeColor: cs.surface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => cs.surface.withValues(alpha: 0.96),
                  tooltipRoundedRadius: 10,
                  tooltipBorder: BorderSide(
                    color: cs.onSurface.withValues(alpha: 0.12),
                  ),
                  getTooltipItems: (spots) {
                    if (spots.isEmpty) return const [];

                    final i = spots.first.x.round().clamp(0, series.length - 1);
                    final day = series[i];
                    final head = DateFormat('d MMMM', locale).format(day.date);

                    // Sarlavha birinchi qatorga, qolgani seriya rangi bilan.
                    return [
                      LineTooltipItem(
                        '$head\n',
                        TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        children: [
                          _tip(incomeLabel, day.income, incomeColor, locale),
                          _tip(profitLabel, day.profit, profitColor, locale),
                          _tip(expenseLabel, day.expense, expenseColor, locale),
                        ],
                      ),
                      ...List.filled(spots.length - 1, null),
                    ];
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _bar(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      color: color,
      // barWidth standarti 2 — ingichka chiziq ataylab shunday qoldirilgan.
      isCurved: true,
      curveSmoothness: 0.22,
      preventCurveOverShooting: true,
      // 30 nuqtaga nuqta qo'yilsa grafik chalkashadi — faqat teginganda ko'rinadi.
      dotData: const FlDotData(show: false),
    );
  }

  TextSpan _tip(String label, double value, Color color, String locale) {
    final n = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0)
        .format(value);

    return TextSpan(
      text: '\n$label: $n $moneySuffix',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
      ),
    );
  }

  /// Nuqta ko'p bo'lganda barcha sanani yozib bo'lmaydi — 4–5 ta yorliq qoladi.
  static double _labelInterval(int count) {
    if (count <= 7) return 1;

    return (count / 5).ceilToDouble();
  }

  /// O'q yorlig'i uchun qisqa ko'rinish: 1 250 000 -> 1,2M
  static String _compact(double v) {
    final a = v.abs();
    final sign = v < 0 ? '-' : '';

    if (a >= 1000000) {
      return '$sign${(a / 1000000).toStringAsFixed(a >= 10000000 ? 0 : 1)}M';
    }

    if (a >= 1000) {
      return '$sign${(a / 1000).toStringAsFixed(a >= 10000 ? 0 : 1)}K';
    }

    return v.toStringAsFixed(0);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          // Matn rang bilan emas, doira bilan belgilanadi.
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
