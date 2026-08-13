import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/widgets/segmented_tabs.dart';

/// Kassa, statistika va zakazlar sahifalari shu bitta widgetni ishlatadi —
/// uchalasining ko'rinishi ajralib ketmasligi uchun.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedTabs<String>(
            tabs: const ['Barchasi', 'Oylik', 'Kunlik'],
            labelOf: (t) => t,
            selected: selected,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('barcha bo‘limlar ko‘rinadi', (tester) async {
    await pump(tester, selected: 'Oylik', onChanged: (_) {});

    expect(find.text('Barchasi'), findsOneWidget);
    expect(find.text('Oylik'), findsOneWidget);
    expect(find.text('Kunlik'), findsOneWidget);
  });

  testWidgets('boshqa bo‘lim bosilsa xabar beriladi', (tester) async {
    String? picked;
    await pump(tester, selected: 'Oylik', onChanged: (t) => picked = t);

    await tester.tap(find.text('Kunlik'));
    expect(picked, 'Kunlik');
  });

  testWidgets('tanlangan bo‘lim qayta bosilsa xabar berilmaydi', (tester) async {
    // Aks holda har bosishda ma'lumot qaytadan yuklanardi.
    var calls = 0;
    await pump(tester, selected: 'Oylik', onChanged: (_) => calls++);

    await tester.tap(find.text('Oylik'));
    expect(calls, 0);
  });

  testWidgets('tanlangan bo‘lim rangi bilan ajralib turadi', (tester) async {
    await pump(tester, selected: 'Oylik', onChanged: (_) {});

    final cs = ThemeData.light().colorScheme;
    final active = tester.widget<Text>(find.text('Oylik')).style!;
    final idle = tester.widget<Text>(find.text('Kunlik')).style!;

    expect(active.color, cs.primary);
    expect(idle.color, isNot(cs.primary));
  });
}
