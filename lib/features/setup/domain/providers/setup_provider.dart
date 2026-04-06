import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/setup_repository.dart';
import '../models/bread_category_model.dart';
import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';

final setupRepositoryProvider = Provider<SetupRepository>((ref) {
  return SetupRepository(ref.read(apiClientProvider));
});

String _shopId(Ref ref) => ref.read(shopProvider).selected!.id;

// -- BreadCategory --
class BreadCategoryListState {
  final List<BreadCategoryModel> items;
  final bool isLoading;
  final String? error;

  const BreadCategoryListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  BreadCategoryListState copyWith({
    List<BreadCategoryModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return BreadCategoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BreadCategoryNotifier extends Notifier<BreadCategoryListState> {
  @override
  BreadCategoryListState build() => const BreadCategoryListState();

  SetupRepository get _repo => ref.read(setupRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getBreadCategories(_shopId(ref));
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String name,
    required double sellingPrice,
    required String currencyId,
  }) async {
    try {
      await _repo.createBreadCategory(
        _shopId(ref),
        name: name,
        sellingPrice: sellingPrice,
        currencyId: currencyId,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> update({
    required String id,
    required String name,
    required double sellingPrice,
    required String currencyId,
  }) async {
    try {
      await _repo.updateBreadCategory(
        _shopId(ref),
        id,
        name: name,
        sellingPrice: sellingPrice,
        currencyId: currencyId,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.deleteBreadCategory(_shopId(ref), id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final breadCategoryProvider =
    NotifierProvider<BreadCategoryNotifier, BreadCategoryListState>(BreadCategoryNotifier.new);

// -- Ingredient --
class IngredientListState {
  final List<IngredientModel> items;
  final bool isLoading;
  final String? error;

  const IngredientListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  IngredientListState copyWith({
    List<IngredientModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return IngredientListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class IngredientNotifier extends Notifier<IngredientListState> {
  @override
  IngredientListState build() => const IngredientListState();

  SetupRepository get _repo => ref.read(setupRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getIngredients(_shopId(ref));
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String name,
    required String measurementUnitId,
    required double pricePerUnit,
    required String currencyId,
    bool isFlour = false,
  }) async {
    try {
      await _repo.createIngredient(
        _shopId(ref),
        name: name,
        measurementUnitId: measurementUnitId,
        pricePerUnit: pricePerUnit,
        currencyId: currencyId,
        isFlour: isFlour,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> update({
    required String id,
    required String name,
    required String measurementUnitId,
    required double pricePerUnit,
    required String currencyId,
  }) async {
    try {
      await _repo.updateIngredient(
        _shopId(ref),
        id,
        name: name,
        measurementUnitId: measurementUnitId,
        pricePerUnit: pricePerUnit,
        currencyId: currencyId,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.deleteIngredient(_shopId(ref), id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final ingredientProvider =
    NotifierProvider<IngredientNotifier, IngredientListState>(IngredientNotifier.new);

// -- Recipe --
class RecipeListState {
  final List<RecipeModel> items;
  final bool isLoading;
  final String? error;

  const RecipeListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  RecipeListState copyWith({
    List<RecipeModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return RecipeListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RecipeNotifier extends Notifier<RecipeListState> {
  @override
  RecipeListState build() => const RecipeListState();

  SetupRepository get _repo => ref.read(setupRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getRecipes(_shopId(ref));
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String breadCategoryId,
    required String measurementUnitId,
    required String name,
    required int outputQuantity,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    try {
      await _repo.createRecipe(
        _shopId(ref),
        breadCategoryId: breadCategoryId,
        measurementUnitId: measurementUnitId,
        name: name,
        outputQuantity: outputQuantity,
        ingredients: ingredients,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.deleteRecipe(_shopId(ref), id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final recipeProvider =
    NotifierProvider<RecipeNotifier, RecipeListState>(RecipeNotifier.new);
