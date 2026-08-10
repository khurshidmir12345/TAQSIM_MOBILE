import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/cash_model.dart';

class CashRepository {
  final ApiClient _apiClient;

  CashRepository(this._apiClient);

  String _path(String shopId) => '/v1/shops/$shopId/cash';

  /// Davr xulosasi, sozlama va yozuvlar — bitta so'rovda.
  Future<CashPage> fetch(
    String shopId, {
    required DateTime from,
    required DateTime to,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        _path(shopId),
        queryParameters: {
          'from': _ymd(from),
          'to': _ymd(to),
          'page': page,
        },
      );

      return CashPage.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CashEntry> create(
    String shopId, {
    required CashType type,
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        _path(shopId),
        data: {
          'type': type == CashType.income ? 'income' : 'expense',
          'category': category,
          'amount': amount,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'date': _ymd(date),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;

      return CashEntry.fromJson(data['entry'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CashEntry> update(
    String shopId,
    String entryId, {
    double? amount,
    String? category,
    String? description,
    DateTime? date,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '${_path(shopId)}/$entryId',
        data: {
          'amount': ?amount,
          'category': ?category,
          'description': ?description?.trim(),
          'date': ?(date == null ? null : _ymd(date)),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;

      return CashEntry.fromJson(data['entry'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String shopId, String entryId) async {
    try {
      await _apiClient.dio.delete('${_path(shopId)}/$entryId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CashSettings> updateSettings(
    String shopId, {
    bool? trackProduction,
    bool? trackReturns,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '${_path(shopId)}/settings',
        data: {
          'track_production': ?trackProduction,
          'track_returns': ?trackReturns,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;

      return CashSettings.fromJson(data['settings'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Kirim turlari — server foydalanuvchi tilida qaytaradi.
  Future<List<CashCategoryOption>> incomeCategories(String shopId) async {
    try {
      final response =
          await _apiClient.dio.get('${_path(shopId)}/income-categories');
      final data = response.data['data'] as Map<String, dynamic>;
      final list = data['categories'] as List<dynamic>? ?? const [];

      return list
          .map((e) => CashCategoryOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
