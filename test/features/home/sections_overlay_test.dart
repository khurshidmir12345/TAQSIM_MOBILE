import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/core/l10n/app_locale.dart';
import 'package:taqseem/features/home/presentation/widgets/sections_drawer.dart';

class _TestLocale extends LocaleNotifier {
  @override
  Future<AppLocale> build() async => AppLocale.uz;
}

void main() {
  testWidgets('edge handle opens blurred sections overlay with outlet button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localeProvider.overrideWith(_TestLocale.new)],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: SectionsEdgeHandle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Do‘konlar'), findsNothing);

    await tester.tap(find.byType(SectionsEdgeHandle));
    await tester.pumpAndSettle();

    expect(find.text('Do‘konlar'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);

    // Bo'sh joyga bosilsa yopiladi.
    await tester.tapAt(const Offset(40, 300));
    await tester.pumpAndSettle();
    expect(find.text('Do‘konlar'), findsNothing);
  });
}
