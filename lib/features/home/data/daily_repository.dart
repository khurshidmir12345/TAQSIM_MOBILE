import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/bread_return_model.dart';
import '../domain/models/daily_report_model.dart';
import '../domain/models/expense_category_option.dart';
import '../domain/models/expense_model.dart';
import '../domain/models/paginated_result.dart';
import '../domain/models/production_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

class DailyRepository {
  final ApiClient _apiClient;

  DailyRepository(this._apiClient);

  String _shopPath(String shopId) => '/v1/shops/$shopId';

  Future<PaginatedResult<ProductionModel>> fetchProductionsPaginated(
    String shopId, {
    required int page,
    int perPage = 20,
  }) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/productions',
        queryParameters: {
          'paginate': true,
          'page': page,
          'per_page': perPage,
        },
      );
      final root = _body(res);
      final list = root['data'] as List;
      final meta = root['meta'] as Map<String, dynamic>;
      final items = list
          .map((e) => ProductionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResult<ProductionModel>(
        items: items,
        currentPage: (meta['current_page'] as num).toInt(),
        lastPage: (meta['last_page'] as num).toInt(),
        perPage: (meta['per_page'] as num).toInt(),
        total: (meta['total'] as num).toInt(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PaginatedResult<BreadReturnModel>> fetchReturnsPaginated(
    String shopId, {
    required int page,
    int perPage = 20,
  }) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/returns',
        queryParameters: {
          'paginate': true,
          'page': page,
          'per_page': perPage,
        },
      );
      final root = _body(res);
      final list = root['data'] as List;
      final meta = root['meta'] as Map<String, dynamic>;
      final items = list
          .map((e) => BreadReturnModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResult<BreadReturnModel>(
        items: items,
        currentPage: (meta['current_page'] as num).toInt(),
        lastPage: (meta['last_page'] as num).toInt(),
        perPage: (meta['per_page'] as num).toInt(),
        total: (meta['total'] as num).toInt(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ProductionModel>> getProductions(String shopId, String date) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/productions',
        queryParameters: {'date': date},
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      final list = data['productions'] as List;
      return list.map((e) => ProductionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductionModel> createProduction(
    String shopId, {
    required String recipeId,
    required String breadCategoryId,
    required String date,
    required double batchCount,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${_shopPath(shopId)}/productions',
        data: {
          'recipe_id': recipeId,
          'bread_category_id': breadCategoryId,
          'date': date,
          'batch_count': batchCount,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return ProductionModel.fromJson(data['production'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteProduction(String shopId, String id) async {
    try {
      await _apiClient.dio.delete('${_shopPath(shopId)}/productions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductionModel> updateProduction(
    String shopId,
    String productionId, {
    required double batchCount,
  }) async {
    try {
      final res = await _apiClient.dio.put(
        '${_shopPath(shopId)}/productions/$productionId',
        data: {'batch_count': batchCount},
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return ProductionModel.fromJson(data['production'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<BreadReturnModel>> getReturns(String shopId, String date) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/returns',
        queryParameters: {'date': date},
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      final list = data['returns'] as List;
      return list.map((e) => BreadReturnModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BreadReturnModel> createReturn(
    String shopId, {
    required String productionId,
    required String breadCategoryId,
    required String date,
    required int quantity,
    required double pricePerUnit,
    String? reason,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${_shopPath(shopId)}/returns',
        data: {
          'production_id': productionId,
          'bread_category_id': breadCategoryId,
          'date': date,
          'quantity': quantity,
          'price_per_unit': pricePerUnit,
          if (reason != null) 'reason': reason,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return BreadReturnModel.fromJson(data['return'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteReturn(String shopId, String id) async {
    try {
      await _apiClient.dio.delete('${_shopPath(shopId)}/returns/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ExpenseModel>> getExpenses(
    String shopId,
    String date, {
    String? locale,
  }) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/expenses',
        queryParameters: {
          'date': date,
          if (locale != null) 'locale': locale,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      final list = data['expenses'] as List;
      return list.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ExpenseModel> createExpense(
    String shopId, {
    required String category,
    String? description,
    required double amount,
    required String date,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${_shopPath(shopId)}/expenses',
        data: {
          'category': category,
          'amount': amount,
          'date': date,
          if (description != null) 'description': description,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return ExpenseModel.fromJson(data['expense'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ExpenseCategoryOption>> fetchExpenseCategories(
    String shopId, {
    String? search,
    required String locale,
  }) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/expense-categories',
        queryParameters: {
          'locale': locale,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      final list = data['categories'] as List;
      return list
          .map((e) => ExpenseCategoryOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ExpenseCategoryOption> createExpenseCategory(
    String shopId, {
    required String name,
    String? locale,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${_shopPath(shopId)}/expense-categories',
        data: {
          'name': name,
          if (locale != null) 'locale': locale,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return ExpenseCategoryOption.fromJson(
        data['category'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DailyReportModel> getDailyReport(String shopId, String date) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/reports/daily',
        queryParameters: {'date': date},
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return DailyReportModel.fromJson(data['report'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DailyReportModel> getRangeReport(
    String shopId,
    String from,
    String to,
  ) async {
    try {
      final res = await _apiClient.dio.get(
        '${_shopPath(shopId)}/reports/range',
        queryParameters: {'from': from, 'to': to},
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return DailyReportModel.fromJson(data['report'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
