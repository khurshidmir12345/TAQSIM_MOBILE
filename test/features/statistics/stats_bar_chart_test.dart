import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/features/statistics/domain/models/statistics_model.dart';
import 'package:taqseem/features/statistics/presentation/widgets/stats_bar_chart.dart';

void main() {
  final series = [
    for (var i = 0; i < 7; i++)
      StatPoint(
        date: DateTime(2026, 9, 10 + i),
        income: 100000.0 * (i + 1),
        expense: 40000.0 * (i + 1),
        profit: i == 3 ? -20000 : 60000.0 * (i + 1),
      ),
  ];
  const totals = StatTotals(income: 2800000, expense: 1120000, profit: 1500000);

  Widget harness() => MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StatsBarChart(
          series: series,
          totals: totals,
          incomeLabel: 'Daromad',
          expenseLabel: 'Xarajat',
          profitLabel: 'Foyda',
          periodTotalLabel: 'Davr jami',
          hint: 'Ustunni bosing',
          moneySuffix: 'so‘m',
        ),
      ),
    ),
  );

  testWidgets('shows all three totals and highlights a metric', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Uchala jami bir vaqtda ko'rinadi.
    expect(find.text('Davr jami'), findsOneWidget);
    expect(find.text('2,800,000 so‘m'), findsOneWidget);
    expect(find.text('1,120,000 so‘m'), findsOneWidget);
    expect(find.text('1,500,000 so‘m'), findsOneWidget);

    // Legenda bosilsa ajratiladi, summalar joyida qoladi.
    await tester.tap(find.text('Foyda'));
    await tester.pumpAndSettle();
    expect(find.text('2,800,000 so‘m'), findsOneWidget);
    expect(find.text('1,500,000 so‘m'), findsOneWidget);
  });
}
