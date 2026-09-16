import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/core/l10n/app_locale.dart';
import 'package:taqseem/features/auth/domain/models/shop_model.dart';
import 'package:taqseem/features/auth/domain/providers/shop_provider.dart';
import 'package:taqseem/features/home/domain/models/ingredient_usage_model.dart';
import 'package:taqseem/features/home/domain/providers/daily_provider.dart';
import 'package:taqseem/features/home/presentation/screens/ingredient_usage_screen.dart';

const _shop = ShopModel(id: 's1', name: 'Test shop', slug: 'test-shop');

const _usage = IngredientUsageModel(
  from: '2026-09-16',
  to: '2026-09-16',
  productionCount: 2,
  totalCost: 302000,
  items: [
    IngredientUsageItem(
      ingredientId: 'i1',
      name: 'Un',
      unit: 'kg',
      isFlour: true,
      pricePerUnit: 5000,
      quantity: 60,
      cost: 300000,
      byProduct: [
        IngredientUsageByProduct(name: 'Non', quantity: 50),
        IngredientUsageByProduct(name: 'Patir', quantity: 10),
      ],
    ),
    IngredientUsageItem(
      ingredientId: 'i2',
      name: 'Tuz',
      unit: 'kg',
      isFlour: false,
      pricePerUnit: 2000,
      quantity: 1,
      cost: 2000,
      byProduct: [IngredientUsageByProduct(name: 'Non', quantity: 1)],
    ),
  ],
);

class _TestShopNotifier extends ShopNotifier {
  @override
  ShopState build() => const ShopState(selected: _shop);
}

class _TestLocale extends LocaleNotifier {
  @override
  Future<AppLocale> build() async => AppLocale.uz;
}

void main() {
  testWidgets('lists ingredient usage with totals and product split', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopProvider.overrideWith(_TestShopNotifier.new),
          localeProvider.overrideWith(_TestLocale.new),
          ingredientUsageProvider.overrideWith((ref, date) async => _usage),
        ],
        child: MaterialApp(
          home: IngredientUsageScreen(initialDate: DateTime(2026, 9, 16)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xom ashyo sarfi'), findsOneWidget);
    expect(find.textContaining('302,000'), findsOneWidget);
    expect(find.textContaining('2 ta chiqim'), findsOneWidget);
    expect(find.text('Un'), findsOneWidget);
    expect(find.text('60 kg'), findsOneWidget);
    expect(find.text('Tuz'), findsOneWidget);
    expect(find.text('Non'), findsNothing);

    // Qator bosilsa mahsulotlar kesimi ochiladi.
    await tester.tap(find.text('Un'));
    await tester.pumpAndSettle();
    expect(find.text('Non'), findsOneWidget);
    expect(find.text('Patir'), findsOneWidget);
    expect(find.text('50 kg'), findsOneWidget);
  });
}
