import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_provider.dart';
import '../../data/shop_repository.dart';
import '../models/business_type_model.dart';
import '../models/currency_model.dart';
import '../models/measurement_unit_model.dart';
import '../models/shop_model.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.read(apiClientProvider));
});

/// Fetches available business types (cached with AsyncNotifier).
final businessTypesProvider =
    AsyncNotifierProvider<_BusinessTypesNotifier, List<BusinessTypeModel>>(
  _BusinessTypesNotifier.new,
);

class _BusinessTypesNotifier
    extends AsyncNotifier<List<BusinessTypeModel>> {
  @override
  Future<List<BusinessTypeModel>> build() {
    return ref.read(shopRepositoryProvider).getBusinessTypes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(shopRepositoryProvider).getBusinessTypes(),
    );
  }
}

// ─── Currencies ───────────────────────────────────────────────────────────────

final currenciesProvider =
    AsyncNotifierProvider<_CurrenciesNotifier, List<CurrencyModel>>(
  _CurrenciesNotifier.new,
);

class _CurrenciesNotifier extends AsyncNotifier<List<CurrencyModel>> {
  @override
  Future<List<CurrencyModel>> build() {
    return ref.read(shopRepositoryProvider).getCurrencies();
  }
}

/// Xom ashyo uchun faqat kg, l, m, ta (backend filtri).
final ingredientMeasurementUnitsProvider = AsyncNotifierProvider<
    _IngredientMeasurementUnitsNotifier, List<MeasurementUnitModel>>(
  _IngredientMeasurementUnitsNotifier.new,
);

class _IngredientMeasurementUnitsNotifier
    extends AsyncNotifier<List<MeasurementUnitModel>> {
  @override
  Future<List<MeasurementUnitModel>> build() {
    return ref.read(shopRepositoryProvider).getIngredientMeasurementUnits();
  }
}

/// Retsept partiya birliklari (carousel) — `/v1/measurement-units/batch`.
final recipeBatchUnitsProvider = AsyncNotifierProvider<
    _RecipeBatchUnitsNotifier, List<MeasurementUnitModel>>(
  _RecipeBatchUnitsNotifier.new,
);

class _RecipeBatchUnitsNotifier
    extends AsyncNotifier<List<MeasurementUnitModel>> {
  @override
  Future<List<MeasurementUnitModel>> build() {
    return ref.read(shopRepositoryProvider).getBatchMeasurementUnits();
  }
}

// ─── Measurement Units ────────────────────────────────────────────────────────

final measurementUnitsProvider =
    AsyncNotifierProvider<_MeasurementUnitsNotifier, List<MeasurementUnitModel>>(
  _MeasurementUnitsNotifier.new,
);

class _MeasurementUnitsNotifier
    extends AsyncNotifier<List<MeasurementUnitModel>> {
  @override
  Future<List<MeasurementUnitModel>> build() {
    return ref.read(shopRepositoryProvider).getMeasurementUnits();
  }
}

extension MeasurementUnitsExt on List<MeasurementUnitModel> {
  List<MeasurementUnitModel> get ingredients => where((u) => u.isIngredient).toList();
  List<MeasurementUnitModel> get batches      => where((u) => u.isBatch).toList();
}

// ─── Shop State ───────────────────────────────────────────────────────────────

const _kSelectedShopId = 'selected_shop_id_v1';

class ShopState {
  final List<ShopModel> shops;
  final ShopModel? selected;
  final bool isLoading;
  final String? error;

  const ShopState({
    this.shops    = const [],
    this.selected,
    this.isLoading = false,
    this.error,
  });

  ShopState copyWith({
    List<ShopModel>? shops,
    ShopModel? selected,
    bool? isLoading,
    String? error,
  }) {
    return ShopState(
      shops:     shops     ?? this.shops,
      selected:  selected  ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }
}

class ShopNotifier extends Notifier<ShopState> {
  @override
  ShopState build() => const ShopState();

  ShopRepository get _repo => ref.read(shopRepositoryProvider);

  Future<void> loadShops() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final shops = await _repo.getShops();
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kSelectedShopId);

      ShopModel? selected;
      if (savedId != null) {
        selected = shops.where((s) => s.id == savedId).firstOrNull;
      }
      final prevSelected = state.selected;
      if (selected == null && prevSelected != null) {
        selected = shops.where((s) => s.id == prevSelected.id).firstOrNull;
      }
      selected ??= shops.isNotEmpty ? shops.first : null;

      if (selected != null) {
        await prefs.setString(_kSelectedShopId, selected.id);
      } else {
        await prefs.remove(_kSelectedShopId);
      }

      state = state.copyWith(
        shops: shops,
        selected: selected,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _persistSelectedId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedShopId, id);
  }

  void selectShop(ShopModel shop) {
    state = state.copyWith(selected: shop);
    Future.microtask(() => _persistSelectedId(shop.id));
  }

  /// Chiqish yoki akkaunt o‘chirishda — cache va state tozalanadi.
  Future<void> resetOnLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSelectedShopId);
    state = const ShopState();
  }

  Future<void> createShop({
    required String businessTypeId,
    required String currencyId,
    required String name,
    String? customBusinessTypeName,
    List<String> ingredientUnitIds = const [],
    List<String> batchUnitIds      = const [],
    String? description,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    final shop = await _repo.createShop(
      businessTypeId:          businessTypeId,
      currencyId:              currencyId,
      name:                    name,
      customBusinessTypeName:  customBusinessTypeName,
      ingredientUnitIds:       ingredientUnitIds,
      batchUnitIds:            batchUnitIds,
      description:             description,
      address:                 address,
      phone:                   phone,
      latitude:                latitude,
      longitude:               longitude,
    );
    final newList = [...state.shops, shop];
    state = state.copyWith(
      shops: newList,
      selected: shop,
    );
    await _persistSelectedId(shop.id);
  }
}

final shopProvider = NotifierProvider<ShopNotifier, ShopState>(ShopNotifier.new);
