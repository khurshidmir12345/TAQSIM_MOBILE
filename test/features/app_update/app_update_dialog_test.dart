import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/features/app_update/domain/models/app_update_info.dart';
import 'package:taqseem/features/app_update/presentation/app_update_dialog.dart';

/// Yangilanish modalkasi o'z-o'zidan yopilmasligi kerak.
///
/// Avval modalka splash paytida chiqarilardi va go_router asosiy sahifaga
/// o'tayotganda uni bosilmasdan yopib yuborardi. Endi modalka asosiy sahifada
/// chiqadi va faqat tugmalar orqali yopiladi.
void main() {
  const info = AppUpdateInfo(
    enabled: true,
    updateAvailable: true,
    latestVersion: '1.2.8',
    storeUrl: 'https://play.google.com/store/apps/details?id=uz.taqseem.mobile',
  );

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AppUpdateDialog.show(context, info),
              child: const Text('och'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('och'));
    await tester.pumpAndSettle();
  }

  testWidgets('fon bosilsa modalka yopilmaydi', (tester) async {
    await openDialog(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    // Modalka tashqarisi — chap yuqori burchak.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('tizim "orqaga" tugmasi modalkani yopmaydi', (tester) async {
    await openDialog(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('"Keyinroq" bosilganda modalka yopiladi', (tester) async {
    await openDialog(tester);

    // Til testda muhim emas — "Keyinroq" yagona TextButton, "Yangilash" esa
    // FilledButton.
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('do\'kon havolasi bo\'lsa "Yangilash" tugmasi chiqadi',
      (tester) async {
    await openDialog(tester);

    expect(find.byType(FilledButton), findsOneWidget);
  });
}
