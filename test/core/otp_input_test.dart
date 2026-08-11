import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/widgets/otp_input.dart';

/// SMS kodini kiritish maydoni.
///
/// Asosiy xavf — avtomatik to'ldirish: telefon klaviatura ustidan taklif
/// qilgan to'liq kod bir zarbda tushadi. Avval har bir katak alohida maydon
/// edi va uzunlik cheklovi kodni bitta raqamgacha qirqib tashlardi.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required void Function(String) onCompleted,
    void Function(String)? onChanged,
    int length = 4,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInput(
            length: length,
            onCompleted: onCompleted,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Finder hiddenField() => find.byType(TextField);

  testWidgets('to\'liq kod bir zarbda tushsa hammasi qabul qilinadi',
      (tester) async {
    String? completed;

    await pump(tester, onCompleted: (c) => completed = c);
    await tester.enterText(hiddenField(), '1234');
    await tester.pump();

    expect(completed, '1234');
  });

  testWidgets('kod kataklarda ko\'rinadi', (tester) async {
    await pump(tester, onCompleted: (_) {});
    await tester.enterText(hiddenField(), '5678');
    await tester.pump();

    for (final digit in ['5', '6', '7', '8']) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('raqam bo\'lmagan belgilar tashlab yuboriladi', (tester) async {
    String? completed;

    await pump(tester, onCompleted: (c) => completed = c);
    await tester.enterText(hiddenField(), 'a1b2c3d4');
    await tester.pump();

    expect(completed, '1234');
  });

  testWidgets('uzunlikdan ortiq raqamlar kesiladi', (tester) async {
    String? completed;

    await pump(tester, onCompleted: (c) => completed = c);
    await tester.enterText(hiddenField(), '123456');
    await tester.pump();

    expect(completed, '1234');
  });

  testWidgets('to\'lmagan kodda onCompleted chaqirilmaydi', (tester) async {
    var completedCount = 0;
    final changes = <String>[];

    await pump(
      tester,
      onCompleted: (_) => completedCount++,
      onChanged: changes.add,
    );

    await tester.enterText(hiddenField(), '12');
    await tester.pump();

    expect(completedCount, 0);
    expect(changes.last, '12');
  });

  testWidgets('clear kodni bo\'shatadi', (tester) async {
    await pump(tester, onCompleted: (_) {});
    await tester.enterText(hiddenField(), '1234');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    final state = tester.state<OtpInputState>(find.byType(OtpInput));
    state.clear();
    await tester.pump();

    expect(find.text('1'), findsNothing);
  });

  testWidgets('6 xonali kod ham qo\'llab-quvvatlanadi', (tester) async {
    String? completed;

    await pump(tester, onCompleted: (c) => completed = c, length: 6);
    await tester.enterText(hiddenField(), '987654');
    await tester.pump();

    expect(completed, '987654');
  });

  testWidgets('avtomatik to\'ldirish uchun oneTimeCode belgisi bor',
      (tester) async {
    await pump(tester, onCompleted: (_) {});

    final field = tester.widget<TextField>(hiddenField());

    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
  });
}
