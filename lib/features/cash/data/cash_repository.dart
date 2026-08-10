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

  // ─── Kategoriyalar ────────────────────────────────────────────────────

  String _categoryPath(String shopId) => '/v1/shops/$shopId/expense-categories';

  /// Tanlangan yo'nalish uchun turlar: tizimniki + foydalanuvchi qo'shganlari.
  Future<List<CashCategory>> categories(
    String shopId, {
    required CashType type,
    required String locale,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        _categoryPath(shopId),
        queryParameters: {
          'type': type == CashType.income ? 'income' : 'expense',
          'locale': locale,
          'search': ?(search?.trim().isEmpty ?? true ? null : search!.trim()),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final list = data['categories'] as List<dynamic>? ?? const [];

      return list
          .map((e) => CashCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CashCategory> createCategory(
    String shopId, {
    required CashType type,
    required String name,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${_categoryPath(shopId)}?type=${type == CashType.income ? 'income' : 'expense'}',
        data: {'name': name.trim()},
      );

      final data = response.data['data'] as Map<String, dynamic>;

      return CashCategory.fromJson(data['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CashCategory> renameCategory(
    String shopId,
    String categoryId, {
    required String name,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '${_categoryPath(shopId)}/$categoryId',
        data: {'name': name.trim()},
      );

      final data = response.data['data'] as Map<String, dynamic>;

      return CashCategory.fromJson(data['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteCategory(String shopId, String categoryId) async {
    try {
      await _apiClient.dio.delete('${_categoryPath(shopId)}/$categoryId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
