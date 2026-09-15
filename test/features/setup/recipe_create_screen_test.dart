import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taqseem/core/l10n/app_locale.dart';
import 'package:taqseem/features/auth/domain/models/measurement_unit_model.dart';
import 'package:taqseem/features/auth/domain/models/shop_model.dart';
import 'package:taqseem/features/auth/domain/providers/shop_provider.dart';
import 'package:taqseem/features/setup/domain/models/bread_category_model.dart';
import 'package:taqseem/features/setup/domain/models/ingredient_model.dart';
import 'package:taqseem/features/setup/domain/providers/setup_provider.dart';
import 'package:taqseem/features/setup/presentation/screens/recipe_create_screen.dart';

const _shop = ShopModel(id: 's1', name: 'Test shop', slug: 'test-shop');

const _units = [
  MeasurementUnitModel(
    id: 'u-qop',
    type: 'batch',
    code: 'qop',
    icon: '🧺',
    name: 'Qop',
    names: {'uz': 'Qop'},
    examples: {},
    sortOrder: 1,
  ),
  MeasurementUnitModel(
    id: 'u-dona',
    type: 'batch',
    code: 'dona_batch',
    icon: '🔢',
    name: 'Dona (partiya)',
    names: {'uz': 'Dona (partiya)'},
    examples: {},
    sortOrder: 2,
  ),
  MeasurementUnitModel(
    id: 'u-custom',
    type: 'batch',
    code: 'custom_abc',
    icon: '🍽️',
    name: 'Laganda',
    names: {'uz': 'Laganda'},
    examples: {},
    sortOrder: 3,
    isCustom: true,
  ),
];

const _categories = [
  BreadCategoryModel(
    id: 'c1',
    shopId: 's1',
    name: 'Oq non',
    sellingPrice: '4000',
  ),
  BreadCategoryModel(
    id: 'c2',
    shopId: 's1',
    name: 'Patir',
    sellingPrice: '6000',
  ),
];

const _ingredients = [
  IngredientModel(
    id: 'i1',
    shopId: 's1',
    name: 'Un',
    unit: 'kg',
    pricePerUnit: '5000',
  ),
  IngredientModel(
    id: 'i2',
    shopId: 's1',
    name: 'Tuz',
    unit: 'kg',
    pricePerUnit: '2000',
  ),
];

class _TestShopNotifier extends ShopNotifier {
  @override
  ShopState build() => const ShopState(selected: _shop);
}

class _TestCategories extends BreadCategoryNotifier {
  @override
  BreadCategoryListState build() =>
      const BreadCategoryListState(items: _categories);

  @override
  Future<void> load() async {}
}

class _TestIngredients extends IngredientNotifier {
  @override
  IngredientListState build() => const IngredientListState(items: _ingredients);

  @override
  Future<void> load() async {}
}

class _TestRecipes extends RecipeNotifier {
  @override
  RecipeListState build() => const RecipeListState();

  @override
  Future<void> load() async {}
}

class _TestBatchUnits extends RecipeBatchUnitsNotifier {
  @override
  Future<List<MeasurementUnitModel>> build() async => _units;
}

class _TestLocale extends LocaleNotifier {
  @override
  Future<AppLocale> build() async => AppLocale.uz;
}

Widget _harness() {
  return ProviderScope(
    overrides: [
      shopProvider.overrideWith(_TestShopNotifier.new),
      breadCategoryProvider.overrideWith(_TestCategories.new),
      ingredientProvider.overrideWith(_TestIngredients.new),
      recipeProvider.overrideWith(_TestRecipes.new),
      recipeBatchUnitsProvider.overrideWith(_TestBatchUnits.new),
      localeProvider.overrideWith(_TestLocale.new),
    ],
    child: const MaterialApp(home: RecipeCreateScreen()),
  );
}

Future<void> _pumpScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  // Telefon o'lchami + ochiq klavyatura (~300px) — eng tor holat.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_harness());
  await tester.pumpAndSettle();
}

Future<void> _goToStep2(WidgetTester tester) async {
  await tester.tap(find.text('Oq non'));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('step indicator lives in the AppBar, no bottom bar', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Orqaga'), findsNothing);
    expect(find.text('Keyingi'), findsNothing);
    expect(find.text('Oq non'), findsOneWidget);
  });

  testWidgets(
    'set mode reveals carousel with custom "+" card and output field',
    (tester) async {
      await _pumpScreen(tester);
      await _goToStep2(tester);

      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('Bu mahsulot uchun hisob qanday?'), findsOneWidget);
      // Karusel hali yopiq.
      expect(find.text('Qop'), findsNothing);

      await tester.tap(find.text('To‘plam'));
      await tester.pumpAndSettle();

      expect(find.text('Qaysi to‘plam siz uchun ma’qul?'), findsOneWidget);
      expect(find.text('Qop'), findsOneWidget);
      expect(find.text('Laganda'), findsOneWidget);
      expect(find.text('O‘zim'), findsOneWidget);
      // «Dona» to'plam karuselida ko'rinmaydi — u "bir dona" rejimi uchun.
      expect(find.text('Dona'), findsNothing);
      // Birinchi to'plam birligi avtomatik tanlangan → dinamik label.
      expect(find.text('1 qopdan qancha mahsulot chiqadi?'), findsOneWidget);
      expect(find.text('Keyingi'), findsOneWidget);

      // Chiqimsiz "Keyingisi" — xato, 2-qadamda qolamiz.
      await tester.tap(find.text('Keyingi'));
      await tester.pumpAndSettle();
      expect(find.text('Chiqim sonini kiriting'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '50');
      await tester.tap(find.text('Keyingi'));
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('Bir qop uchun xom ashyo miqdori'), findsOneWidget);
    },
  );

  testWidgets('single mode jumps straight to ingredients with piece unit', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _goToStep2(tester);

    await tester.tap(find.text('Bir dona'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('Bir dona uchun xom ashyo miqdori'), findsOneWidget);
    expect(find.text('Saqlash'), findsOneWidget);
  });

  testWidgets(
    'ingredients step guards: empty quantity, then single-ingredient confirm',
    (tester) async {
      await _pumpScreen(tester);
      await _goToStep2(tester);
      await tester.tap(find.text('Bir dona'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Chiplar "+" bilan; bosilsa ro'yxatga qo'shiladi va karuseldan yo'qoladi.
      expect(
        find.text('Xom ashyoni bosing — ro‘yxatga qo‘shiladi'),
        findsOneWidget,
      );
      await tester.tap(find.text('Un'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      // Miqdorsiz saqlash — xato, dialog yo'q.
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.text('Har bir xom ashyo miqdorini kiriting'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      // Bitta xom ashyo bilan saqlash — tasdiq so'raladi.
      await tester.enterText(find.byType(TextField), '25');
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Faqat 1 ta xom ashyo'), findsOneWidget);

      await tester.tap(find.text('Yana qo‘shish'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Tuz'), findsOneWidget);
    },
  );
}
