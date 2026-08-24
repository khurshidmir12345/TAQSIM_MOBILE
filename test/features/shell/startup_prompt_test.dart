import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/features/app_update/domain/models/app_update_info.dart';
import 'package:taqseem/features/app_update/presentation/app_update_dialog.dart';
import 'package:taqseem/features/shell/domain/startup_prompt_provider.dart';
import 'package:taqseem/features/shell/presentation/widgets/startup_prompt_overlay.dart';
import 'package:taqseem/features/telegram_link/presentation/telegram_link_dialog.dart';

/// Asosiy sahifadagi taklif oynasi.
///
/// Avval oyna `showDialog` orqali chiqarilardi va splash `/shell` ga
/// o'tayotganda o'tish animatsiyasi davomida qo'yilgani uchun splash
/// sahifasiga bog'lanib qolardi — splash olib tashlanishi bilan oyna bir
/// zumda yo'q bo'lardi. Endi oyna asosiy sahifa ichida oddiy widget
/// sifatida chiziladi.
void main() {
  const updateInfo = AppUpdateInfo(
    enabled: true,
    updateAvailable: true,
    latestVersion: '1.2.8',
    storeUrl: 'https://play.google.com/store/apps/details?id=uz.taqseem.mobile',
  );

  Future<ProviderContainer> pump(
    WidgetTester tester,
    StartupPromptState initial,
  ) async {
    final container = ProviderContainer(
      overrides: [
        startupPromptProvider.overrideWith(() => _StubNotifier(initial)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Stack(
            children: [
              Scaffold(body: Text('asosiy sahifa')),
              StartupPromptOverlay(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('taklif yo\'q bo\'lsa hech narsa chizilmaydi', (tester) async {
    await pump(tester, const StartupPromptState());

    expect(find.text('asosiy sahifa'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(find.byType(TelegramLinkDialog), findsNothing);
  });

  testWidgets('yangilanish taklifi asosiy sahifa ustida chiziladi',
      (tester) async {
    await pump(
      tester,
      const StartupPromptState(
        prompt: StartupPrompt.appUpdate,
        update: updateInfo,
      ),
    );

    expect(find.byType(AppUpdateDialog), findsOneWidget);
    expect(find.byType(TelegramLinkDialog), findsNothing);
    // Asosiy sahifa ortida turibdi — oyna uni almashtirmaydi.
    expect(find.text('asosiy sahifa'), findsOneWidget);
  });

  testWidgets('fon bosilsa yangilanish taklifi yopilmaydi', (tester) async {
    await pump(
      tester,
      const StartupPromptState(
        prompt: StartupPrompt.appUpdate,
        update: updateInfo,
      ),
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(AppUpdateDialog), findsOneWidget);
  });

  testWidgets('"Keyinroq" bosilganda taklif yopiladi', (tester) async {
    final container = await pump(
      tester,
      const StartupPromptState(
        prompt: StartupPrompt.appUpdate,
        update: updateInfo,
      ),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(container.read(startupPromptProvider).isVisible, isFalse);
  });

  testWidgets('Telegram taklifi alohida chiziladi', (tester) async {
    await pump(
      tester,
      const StartupPromptState(prompt: StartupPrompt.telegramLink),
    );

    expect(find.byType(TelegramLinkDialog), findsOneWidget);
    expect(find.byType(AppUpdateDialog), findsNothing);
  });

  testWidgets('taklif matnida sotuv haqida gap yo\'q', (tester) async {
    await pump(
      tester,
      const StartupPromptState(prompt: StartupPrompt.telegramLink),
    );

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? '').toLowerCase())
        .join(' ');

    for (final banned in [
      'premium', 'obuna', 'subscri', 'pay', 'price', 'narx',
      'sotib', 'tarif', 'upgrade', 'plan',
    ]) {
      expect(texts.contains(banned), isFalse,
          reason: 'Taklif matnida "$banned" bo\'lmasligi kerak');
    }
  });
}

class _StubNotifier extends StartupPromptNotifier {
  _StubNotifier(this._initial);

  final StartupPromptState _initial;

  @override
  StartupPromptState build() => _initial;
}
