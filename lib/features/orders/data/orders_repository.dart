import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/api_exceptions.dart';
import '../../home/domain/models/paginated_result.dart';
import '../domain/models/customer_model.dart';
import '../domain/models/customer_order_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

class CustomerRepository {
  CustomerRepository(Dio dio) : _dio = dio;

  final Dio _dio;

  String _shopPath(String shopId) => '/v1/shops/$shopId';

  Future<List<CustomerModel>> searchCustomers(
    String shopId, {
    String? search,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        '${_shopPath(shopId)}/customers',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
        cancelToken: cancelToken,
      );
      final root = _body(res);
      final data = root['data'];
      if (data is List) {
        return data
            .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final map = data as Map<String, dynamic>;
      final list = map['customers'] as List<dynamic>? ?? const [];
      return list
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PaginatedResult<CustomerModel>> fetchCustomersPaginated(
    String shopId, {
    required int page,
    int perPage = 20,
    String? search,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        '${_shopPath(shopId)}/customers',
        queryParameters: {
          'paginate': true,
          'page': page,
          'per_page': perPage,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          'sort': 'name',
          'order': 'asc',
        },
        cancelToken: cancelToken,
      );
      final root = _body(res);
      final list = root['data'] as List<dynamic>;
      final meta = root['meta'] as Map<String, dynamic>;
      final items = list
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResult<CustomerModel>(
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

  Future<CustomerModel> getCustomer(String shopId, String customerId) async {
    try {
      final res = await _dio.get(
        '${_shopPath(shopId)}/customers/$customerId',
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerModel> createCustomer(
    String shopId, {
    required String name,
    String? phone,
    String? note,
  }) async {
    try {
      final res = await _dio.post(
        '${_shopPath(shopId)}/customers',
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerModel> updateCustomer(
    String shopId,
    String customerId, {
    required String name,
    String? phone,
    String? note,
  }) async {
    try {
      final res = await _dio.put(
        '${_shopPath(shopId)}/customers/$customerId',
        data: {
          'name': name,
          'phone': phone,
          if (note != null) 'note': note,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteCustomer(String shopId, String customerId) async {
    try {
      await _dio.delete(
        '${_shopPath(shopId)}/customers/$customerId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class OrderRepository {
  OrderRepository(Dio dio) : _dio = dio;

  final Dio _dio;

  String _shopPath(String shopId) => '/v1/shops/$shopId';

  Map<String, dynamic> _orderQuery({
    required int page,
    int perPage = 20,
    String? date,
    String? from,
    String? to,
    String? status,
    String? customerId,
  }) {
    return {
      'page': page,
      'per_page': perPage,
      if (date != null) 'date': date,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (status != null) 'status': status,
      if (customerId != null) 'customer_id': customerId,
    };
  }

  Future<PaginatedResult<CustomerOrderModel>> fetchOrdersPaginated(
    String shopId, {
    required int page,
    int perPage = 20,
    String? date,
    String? from,
    String? to,
    String? status,
    String? customerId,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        '${_shopPath(shopId)}/customer-orders',
        queryParameters: _orderQuery(
          page: page,
          perPage: perPage,
          date: date,
          from: from,
          to: to,
          status: status,
          customerId: customerId,
        ),
        cancelToken: cancelToken,
      );
      final root = _body(res);
      final list = root['data'] as List<dynamic>;
      final meta = root['meta'] as Map<String, dynamic>;
      final items = list
          .map(
            (e) => CustomerOrderModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return PaginatedResult<CustomerOrderModel>(
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

  Future<CustomerOrderModel> getOrder(String shopId, String orderId) async {
    try {
      final res = await _dio.get(
        '${_shopPath(shopId)}/customer-orders/$orderId',
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerOrderModel.fromJson(
        data['customer_order'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerOrderModel> createOrder(
    String shopId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.post(
        '${_shopPath(shopId)}/customer-orders',
        data: payload,
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerOrderModel.fromJson(
        data['customer_order'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerOrderModel> updateOrder(
    String shopId,
    String orderId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.put(
        '${_shopPath(shopId)}/customer-orders/$orderId',
        data: payload,
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerOrderModel.fromJson(
        data['customer_order'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerOrderModel> addPayment(
    String shopId,
    String orderId, {
    required num amount,
    String? paidAt,
    String? note,
  }) async {
    try {
      final res = await _dio.post(
        '${_shopPath(shopId)}/customer-orders/$orderId/payments',
        data: {
          'amount': amount,
          if (paidAt != null) 'paid_at': paidAt,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerOrderModel.fromJson(
        data['customer_order'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerOrderModel> deliverOrder(
    String shopId,
    String orderId, {
    num? paymentAmount,
    String? paymentNote,
  }) async {
    try {
      final res = await _dio.post(
        '${_shopPath(shopId)}/customer-orders/$orderId/deliver',
        data: {
          if (paymentAmount != null && paymentAmount > 0)
            'payment_amount': paymentAmount,
          if (paymentNote != null && paymentNote.isNotEmpty)
            'payment_note': paymentNote,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerOrderModel.fromJson(
        data['customer_order'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerOrderModel> cancelOrder(String shopId, String orderId) async {
    try {
      final res = await _dio.post(
        '${_shopPath(shopId)}/customer-orders/$orderId/cancel',
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return CustomerOrderModel.fromJson(
        data['customer_order'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteOrder(String shopId, String orderId) async {
    try {
      await _dio.delete(
        '${_shopPath(shopId)}/customer-orders/$orderId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.read(apiClientProvider).dio);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(apiClientProvider).dio);
});
