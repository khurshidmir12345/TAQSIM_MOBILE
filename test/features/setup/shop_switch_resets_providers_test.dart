import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taqseem/core/api/api_client.dart';
import 'package:taqseem/features/auth/domain/models/shop_model.dart';
import 'package:taqseem/features/auth/domain/providers/shop_provider.dart';
import 'package:taqseem/features/setup/data/setup_repository.dart';
import 'package:taqseem/features/setup/domain/models/bread_category_model.dart';
import 'package:taqseem/features/setup/domain/providers/setup_provider.dart';

const _s1 = ShopModel(id: 's1', name: 'Birinchi', slug: 's1');
const _s2 = ShopModel(id: 's2', name: 'Ikkinchi', slug: 's2');

/// Har do'kon uchun o'z mahsuloti — qaysi do'kon so'ralgani ko'rinadi.
class _FakeSetupRepo extends SetupRepository {
  _FakeSetupRepo() : super(ApiClient());

  @override
  Future<List<BreadCategoryModel>> getBreadCategories(String shopId) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return [
      BreadCategoryModel(
        id: '$shopId-c',
        shopId: shopId,
        name: '$shopId non',
        sellingPrice: '1000',
      ),
    ];
  }
}

class _TestShopNotifier extends ShopNotifier {
  @override
  ShopState build() => const ShopState(selected: _s1, shops: [_s1, _s2]);
}

void main() {
  test('switching shop clears old products immediately and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        shopProvider.overrideWith(_TestShopNotifier.new),
        setupRepositoryProvider.overrideWithValue(_FakeSetupRepo()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(breadCategoryProvider.notifier).load();
    expect(container.read(breadCategoryProvider).items.single.name, 's1 non');

    container.read(shopProvider.notifier).selectShop(_s2);
    // Eski do'kon ro'yxati darhol yo'qoladi — yangisi kelguncha ham.
    expect(container.read(breadCategoryProvider).items, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(breadCategoryProvider).items.single.name, 's2 non');
  });
}
