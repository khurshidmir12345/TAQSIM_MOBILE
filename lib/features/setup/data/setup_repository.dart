import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/bread_category_model.dart';
import '../domain/models/ingredient_model.dart';
import '../domain/models/recipe_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

class SetupRepository {
  final ApiClient _apiClient;

  SetupRepository(this._apiClient);

  String _shopPath(String shopId) => '/v1/shops/$shopId';

  Future<List<BreadCategoryModel>> getBreadCategories(String shopId) async {
    try {
      final res = await _apiClient.dio.get('${_shopPath(shopId)}/bread-categories');
      final data = _body(res)['data'] as Map<String, dynamic>;
      final list = data['bread_categories'] as List;
      return list.map((e) => BreadCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BreadCategoryModel> createBreadCategory(
    String shopId, {
    required String name,
    required double sellingPrice,
    required String currencyId,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${_shopPath(shopId)}/bread-categories',
        data: {
          'name': name,
          'selling_price': sellingPrice,
          'currency_id': currencyId,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return BreadCategoryModel.fromJson(data['bread_category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BreadCategoryModel> updateBreadCategory(
    String shopId,
    String id, {
    String? name,
    double? sellingPrice,
    String? currencyId,
    bool? isActive,
  }) async {
    try {
      final res = await _apiClient.dio.put(
        '${_shopPath(shopId)}/bread-categories/$id',
        data: {
          'name': ?name,
          'selling_price': ?sellingPrice,
          'currency_id': ?currencyId,
          'is_active': ?isActive,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return BreadCategoryModel.fromJson(data['bread_category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteBreadCategory(String shopId, String id) async {
    try {
      await _apiClient.dio.delete('${_shopPath(shopId)}/bread-categories/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<IngredientModel>> getIngredients(String shopId) async {
    try {
      final res = await _apiClient.dio.get('${_shopPath(shopId)}/ingredients');
      final data = _body(res)['data'] as Map<String, dynamic>;
      final list = data['ingredients'] as List;
      return list.map((e) => IngredientModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<IngredientModel> createIngredient(
    String shopId, {
    required String name,
    required String measurementUnitId,
    required double pricePerUnit,
    required String currencyId,
    bool isFlour = false,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${_shopPath(shopId)}/ingredients',
        data: {
          'name': name,
          'measurement_unit_id': measurementUnitId,
          'price_per_unit': pricePerUnit,
          'currency_id': currencyId,
          'is_flour': isFlour,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return IngredientModel.fromJson(data['ingredient'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<IngredientModel> updateIngredient(
    String shopId,
    String id, {
    String? name,
    String? measurementUnitId,
    double? pricePerUnit,
    String? currencyId,
    bool? isFlour,
    bool? isActive,
  }) async {
    try {
      final res = await _apiClient.dio.put(
        '${_shopPath(shopId)}/ingredients/$id',
        data: {
          'name': ?name,
          'measurement_unit_id': ?measurementUnitId,
          'price_per_unit': ?pricePerUnit,
          'currency_id': ?currencyId,
          'is_flour': ?isFlour,
          'is_active': ?isActive,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return IngredientModel.fromJson(data['ingredient'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteIngredient(String shopId, String id) async {
    try {
      await _apiClient.dio.delete('${_shopPath(shopId)}/ingredients/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RecipeModel>> getRecipes(String shopId) async {
    try {
      final res = await _apiClient.dio.get('${_shopPath(shopId)}/recipes');
      final data = _body(res)['data'] as Map<String, dynamic>;
      final list = data['recipes'] as List;
      return list.map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RecipeModel> createRecipe(
    String shopId, {
    required String breadCategoryId,
    required String measurementUnitId,
    required String name,
    required int outputQuantity,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${_shopPath(shopId)}/recipes',
        data: {
          'bread_category_id': breadCategoryId,
          'measurement_unit_id': measurementUnitId,
          'name': name,
          'output_quantity': outputQuantity,
          'ingredients': ingredients,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return RecipeModel.fromJson(data['recipe'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteRecipe(String shopId, String id) async {
    try {
      await _apiClient.dio.delete('${_shopPath(shopId)}/recipes/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
