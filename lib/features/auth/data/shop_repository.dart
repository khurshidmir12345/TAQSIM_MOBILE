import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/business_type_model.dart';
import '../domain/models/currency_model.dart';
import '../domain/models/measurement_unit_model.dart';
import '../domain/models/shop_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository(this._apiClient);

  // ─── Business Types ────────────────────────────────────────────────────────

  Future<List<BusinessTypeModel>> getBusinessTypes() async {
    try {
      final response = await _apiClient.dio.get('/v1/business-types');
      final data = _body(response)['data'] as Map<String, dynamic>;
      final list = data['business_types'] as List;
      return list
          .map((e) => BusinessTypeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Currencies ────────────────────────────────────────────────────────────

  Future<List<CurrencyModel>> getCurrencies() async {
    try {
      final response = await _apiClient.dio.get('/v1/currencies');
      final data = _body(response)['data'] as Map<String, dynamic>;
      final list = data['currencies'] as List;
      return list
          .map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Measurement Units ─────────────────────────────────────────────────────

  Future<List<MeasurementUnitModel>> getBatchMeasurementUnits() async {
    try {
      final response =
          await _apiClient.dio.get('/v1/measurement-units/batch');
      final body = _body(response);
      final list = body['data'] as List;
      return list
          .map((e) => MeasurementUnitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<MeasurementUnitModel>> getIngredientMeasurementUnits() async {
    try {
      final response =
          await _apiClient.dio.get('/v1/measurement-units/ingredient');
      final body = _body(response);
      final list = body['data'] as List;
      return list
          .map((e) => MeasurementUnitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<MeasurementUnitModel>> getMeasurementUnits({
    String? type,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/measurement-units',
        queryParameters: type != null ? {'type': type} : null,
      );
      final body = _body(response);
      final list = body['data'] as List;
      return list
          .map((e) => MeasurementUnitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Shops ─────────────────────────────────────────────────────────────────

  Future<List<ShopModel>> getShops() async {
    try {
      final response = await _apiClient.dio.get('/v1/shops');
      final data = _body(response)['data'] as Map<String, dynamic>;
      final list = data['shops'] as List;
      return list
          .map((e) => ShopModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ShopModel> createShop({
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
    try {
      final response = await _apiClient.dio.post('/v1/shops', data: {
        'business_type_id':           businessTypeId,
        'currency_id':                currencyId,
        'name':                       name,
        if (customBusinessTypeName != null)
          'custom_business_type_name': customBusinessTypeName,
        if (ingredientUnitIds.isNotEmpty) 'ingredient_unit_ids': ingredientUnitIds,
        if (batchUnitIds.isNotEmpty)      'batch_unit_ids':      batchUnitIds,
        if (description != null) 'description': description,
        if (address     != null) 'address':     address,
        if (phone       != null) 'phone':        phone,
        if (latitude    != null) 'latitude':    latitude,
        if (longitude   != null) 'longitude':   longitude,
      });
      final data = _body(response)['data'] as Map<String, dynamic>;
      return ShopModel.fromJson(data['shop'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ShopModel> updateShop(
    String shopId, {
    String? name,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _apiClient.dio.put('/v1/shops/$shopId', data: {
        if (name      != null) 'name':      name,
        if (address   != null) 'address':   address,
        if (phone     != null) 'phone':     phone,
        if (latitude  != null) 'latitude':  latitude,
        if (longitude != null) 'longitude': longitude,
      });
      final data = _body(response)['data'] as Map<String, dynamic>;
      return ShopModel.fromJson(data['shop'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteShop(String shopId) async {
    try {
      await _apiClient.dio.delete('/v1/shops/$shopId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
