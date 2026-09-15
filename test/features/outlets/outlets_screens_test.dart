import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/core/l10n/app_locale.dart';
import 'package:taqseem/features/auth/domain/models/shop_model.dart';
import 'package:taqseem/features/auth/domain/providers/shop_provider.dart';
import 'package:taqseem/features/outlets/domain/models/outlet_model.dart';
import 'package:taqseem/features/outlets/domain/providers/outlet_provider.dart';
import 'package:taqseem/features/outlets/presentation/screens/outlet_detail_screen.dart';
import 'package:taqseem/features/outlets/presentation/screens/outlets_screen.dart';
import 'package:taqseem/features/setup/domain/models/bread_category_model.dart';
import 'package:taqseem/features/setup/domain/providers/setup_provider.dart';

const _shop = ShopModel(id: 's1', name: 'Test shop', slug: 'test-shop');

const _outlet = OutletModel(
  id: 'o1',
  name: 'Chorsu do‘koni',
  address: 'Chorsu bozori',
  phones: ['+998901234567'],
  totals: OutletTotals(
    delivered: 200000,
    returned: 20000,
    paid: 50000,
    balance: 130000,
  ),
);

const _entries = [
  OutletEntryModel(
    id: 'e1',
    type: OutletEntryType.delivery,
    date: '2026-09-10',
    amount: 200000,
    items: [
      OutletEntryItemModel(
        id: 'i1',
        breadCategoryId: 'c1',
        name: 'Non',
        quantity: 50,
        unitPrice: 4000,
        subtotal: 200000,
      ),
    ],
  ),
  OutletEntryModel(
    id: 'e2',
    type: OutletEntryType.payment,
    date: '2026-09-10',
    amount: 50000,
    relatedEntryId: 'e1',
  ),
  OutletEntryModel(
    id: 'e3',
    type: OutletEntryType.returned,
    date: '2026-09-11',
    amount: 20000,
  ),
];

class _TestShopNotifier extends ShopNotifier {
  @override
  ShopState build() => const ShopState(selected: _shop);
}

class _TestOutlets extends OutletsNotifier {
  @override
  OutletsState build() =>
      const OutletsState(items: [_outlet], loadedOnce: true);

  @override
  Future<void> load() async {}
}

class _TestLedger extends OutletLedgerNotifier {
  _TestLedger(super.outletId);

  @override
  OutletLedgerState build() =>
      const OutletLedgerState(outlet: _outlet, entries: _entries);

  @override
  Future<void> load() async {}
}

class _TestCategories extends BreadCategoryNotifier {
  @override
  BreadCategoryListState build() => const BreadCategoryListState(
    items: [
      BreadCategoryModel(
        id: 'c1',
        shopId: 's1',
        name: 'Non',
        sellingPrice: '4000',
      ),
    ],
  );

  @override
  Future<void> load() async {}
}

class _TestLocale extends LocaleNotifier {
  @override
  Future<AppLocale> build() async => AppLocale.uz;
}

Widget _harness(Widget home) {
  return ProviderScope(
    overrides: [
      shopProvider.overrideWith(_TestShopNotifier.new),
      outletsProvider.overrideWith(_TestOutlets.new),
      outletLedgerProvider('o1').overrideWith(() => _TestLedger('o1')),
      breadCategoryProvider.overrideWith(_TestCategories.new),
      localeProvider.overrideWith(_TestLocale.new),
    ],
    child: MaterialApp(home: home),
  );
}

void main() {
  testWidgets('outlet list shows balance and status', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(const OutletsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Chorsu do‘koni'), findsOneWidget);
    expect(find.text('Do‘kon qarzi'), findsNWidgets(2)); // umumiy qator + karta
    expect(find.textContaining('130,000'), findsNWidgets(2));
  });

  testWidgets('outlet detail shows summary, ledger and opens delivery sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(const OutletDetailScreen(outletId: 'o1')));
    await tester.pumpAndSettle();

    expect(find.text('Qoldiq'), findsOneWidget);
    expect(find.text('−130,000'), findsOneWidget);
    expect(find.text('Mahsulot berildi'), findsOneWidget);
    expect(find.text('Berishda naqd'), findsOneWidget);
    expect(find.text('Mahsulot qaytdi'), findsOneWidget);
    expect(find.text('Non × 50'), findsOneWidget);
    expect(find.text('Butun davr'), findsOneWidget);

    await tester.tap(find.text('Berish'));
    await tester.pumpAndSettle();
    expect(find.text('Mahsulot berish'), findsOneWidget);
    expect(find.text('Hozir naqd to‘landi'), findsOneWidget);

    // Miqdor kiritilsa jami hisoblanadi: 3 × 4000.
    await tester.enterText(find.widgetWithText(TextField, '0').first, '3');
    await tester.pumpAndSettle();
    expect(find.textContaining('12,000'), findsOneWidget);
  });
}
