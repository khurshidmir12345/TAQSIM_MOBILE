import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../home/domain/models/paginated_result.dart';
import '../domain/models/order_model.dart';
import '../domain/models/subscription_model.dart';
import '../domain/models/subscription_plan_model.dart';
import '../domain/models/wallet_transaction_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

class SubscriptionRepository {
  final ApiClient apiClient;

  SubscriptionRepository(this.apiClient);

  Future<List<SubscriptionPlanModel>> getPlans() async {
    try {
      final response = await apiClient.dio.get('/v1/subscription/plans');
      final data = _body(response)['data'] as Map<String, dynamic>;
      final list = data['plans'] as List<dynamic>? ?? [];
      return list
          .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SubscriptionStatusModel> getStatus() async {
    try {
      final response = await apiClient.dio.get('/v1/subscription/me');
      final data = _body(response)['data'] as Map<String, dynamic>;
      return SubscriptionStatusModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Tarifni balansdan sotib olish. Xato bo'lsa [ApiException] (insufficient_balance
  /// kodi bilan) otiladi.
  Future<void> purchase(String planId) async {
    try {
      await apiClient.dio.post(
        '/v1/subscription/purchase',
        data: {'plan_id': planId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<double> getBalance() async {
    try {
      final response = await apiClient.dio.get('/v1/wallet');
      final data = _body(response)['data'] as Map<String, dynamic>;
      return (data['balance'] as num?)?.toDouble() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PaginatedResult<WalletTransactionModel>> getTransactions({
    int page = 1,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/v1/wallet/transactions',
        queryParameters: {'page': page},
      );
      return _paginate(response, WalletTransactionModel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Balans to'ldirish karta ma'lumotlari (raqam, egasi, izoh).
  Future<({String? cardNumber, String? cardHolder, String? note})>
      getTopupInfo() async {
    try {
      final response = await apiClient.dio.get('/v1/wallet/topup-info');
      final data = _body(response)['data'] as Map<String, dynamic>;
      return (
        cardNumber: data['card_number'] as String?,
        cardHolder: data['card_holder'] as String?,
        note: data['note'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Balansni to'ldirish so'rovi: summa + chek rasmi (multipart).
  Future<void> topup(double amount, {required String receiptPath}) async {
    try {
      final formData = FormData.fromMap({
        'amount': amount,
        'receipt_image': await MultipartFile.fromFile(receiptPath),
      });
      await apiClient.dio.post('/v1/wallet/topup', data: formData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PaginatedResult<OrderModel>> getOrders({int page = 1}) async {
    try {
      final response = await apiClient.dio.get(
        '/v1/orders',
        queryParameters: {'page': page},
      );
      return _paginate(response, OrderModel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  PaginatedResult<T> _paginate<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final root = _body(response);
    final list = root['data'] as List<dynamic>? ?? [];
    final meta = root['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult<T>(
      items: list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? list.length,
      total: (meta['total'] as num?)?.toInt() ?? list.length,
    );
  }
}
