import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/features/telegram_link/presentation/telegram_link_dialog.dart';

/// Telegram ulash taklifi.
///
/// Bu modalka — bizning yagona aloqa kanalimiz: hisob bilan bog'liq
/// xabarlar bot orqali boradi. Shuning uchun matni **faqat aloqa** haqida
/// bo'lishi kerak, xarid haqida emas.
void main() {
  Future<bool?> openDialog(WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await TelegramLinkDialog.show(context);
              },
              child: const Text('och'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('och'));
    await tester.pumpAndSettle();

    return result;
  }

  testWidgets('"Ulash" bosilganda true qaytadi', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('"Keyinroq" bosilganda modalka yopiladi', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('matn faqat aloqa haqida — xarid haqida emas', (tester) async {
    await openDialog(tester);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? '').toLowerCase())
        .join(' ');

    for (final banned in [
      'premium', 'obuna', 'subscri', 'pay', 'price', 'narx',
      'sotib', 'tarif', 'upgrade', 'plan',
    ]) {
      expect(texts.contains(banned), isFalse,
          reason: 'Modalka matnida "$banned" bo\'lmasligi kerak');
    }
  });
}
