import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/core/l10n/app_locale.dart';
import 'package:taqseem/features/auth/domain/models/measurement_unit_model.dart';
import 'package:taqseem/features/auth/domain/models/shop_model.dart';
import 'package:taqseem/features/auth/domain/providers/shop_provider.dart';
import 'package:taqseem/features/setup/domain/models/ingredient_model.dart';
import 'package:taqseem/features/setup/domain/models/recipe_model.dart';
import 'package:taqseem/features/setup/domain/providers/setup_provider.dart';
import 'package:taqseem/features/setup/presentation/screens/recipe_edit_screen.dart';
import 'package:taqseem/features/setup/presentation/widgets/recipe_ingredient_widgets.dart';

const _shop = ShopModel(id: 's1', name: 'Test shop', slug: 'test-shop');

const _un = IngredientModel(
  id: 'i1',
  shopId: 's1',
  name: 'Un',
  unit: 'kg',
  pricePerUnit: '5000',
);
const _tuz = IngredientModel(
  id: 'i2',
  shopId: 's1',
  name: 'Tuz',
  unit: 'kg',
  pricePerUnit: '2000',
);

const _recipe = RecipeModel(
  id: 'r1',
  shopId: 's1',
  name: 'Oq non',
  outputQuantity: 50,
  measurementUnit: MeasurementUnitModel(
    id: 'u-qop',
    type: 'batch',
    code: 'qop',
    icon: '🧺',
    name: 'Qop',
    names: {'uz': 'Qop'},
    examples: {},
    sortOrder: 1,
  ),
  ingredients: [
    RecipeIngredientModel(
      id: 'ri1',
      ingredientId: 'i1',
      ingredient: _un,
      quantity: '25.000',
    ),
  ],
);

class _TestShopNotifier extends ShopNotifier {
  @override
  ShopState build() => const ShopState(selected: _shop);
}

class _TestIngredients extends IngredientNotifier {
  @override
  IngredientListState build() => const IngredientListState(items: [_un, _tuz]);

  @override
  Future<void> load() async {}
}

class _TestLocale extends LocaleNotifier {
  @override
  Future<AppLocale> build() async => AppLocale.uz;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shopProvider.overrideWith(_TestShopNotifier.new),
        ingredientProvider.overrideWith(_TestIngredients.new),
        localeProvider.overrideWith(_TestLocale.new),
      ],
      child: const MaterialApp(home: RecipeEditScreen(recipe: _recipe)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('prefills output and ingredients, recalculates cost live', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Hisoblashni tahrirlash'), findsOneWidget);
    expect(find.text('1 qopdan qancha mahsulot chiqadi?'), findsOneWidget);
    // Mavjud xom ashyo qatorda, karuselda emas.
    expect(find.widgetWithText(TextField, '25'), findsOneWidget);
    expect(find.text('+ Un'), findsNothing);
    expect(find.text('Tuz'), findsOneWidget);
    // 25 kg × 5000 = 125 000; 1 dona = 2 500.
    expect(find.textContaining('125,000'), findsOneWidget);
    expect(find.textContaining('2,500'), findsOneWidget);

    // Tuz qo'shish → yangi qator, tannarx yangilanadi.
    await tester.tap(find.text('Tuz'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '').last, '5');
    await tester.pumpAndSettle();
    // 125 000 + 5 × 2 000 = 135 000; 1 dona = 2 700.
    expect(find.textContaining('135,000'), findsOneWidget);
    expect(find.textContaining('2,700'), findsOneWidget);
  });

  testWidgets('removing every ingredient blocks save', (tester) async {
    await _pump(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(IngredientEntryTile),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+ Un'), findsNothing);
    expect(find.text('Un'), findsOneWidget); // karuselga qaytdi

    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();
    expect(
      find.text('Kamida bitta xom ashyo qo‘shing'),
      findsAtLeastNWidgets(1),
    );
  });
}
