import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/employee_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

class EmployeeRepository {
  final ApiClient _apiClient;

  EmployeeRepository(this._apiClient);

  String _base(String shopId) => '/v1/shops/$shopId/employees';

  Future<List<EmployeeModel>> getEmployees(String shopId) async {
    try {
      final res = await _apiClient.dio.get(_base(shopId));
      final data = _body(res)['data'] as Map<String, dynamic>;
      return (data['employees'] as List)
          .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> startInvite(
    String shopId, {
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      await _apiClient.dio.post(_base(shopId), data: {
        'name': name,
        'phone': phone,
        'password': password,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<EmployeeModel> confirm(
    String shopId, {
    required String phone,
    required String code,
  }) async {
    try {
      final res = await _apiClient.dio.post('${_base(shopId)}/confirm', data: {
        'phone': phone,
        'code': code,
      });
      final data = _body(res)['data'] as Map<String, dynamic>;
      return EmployeeModel.fromJson(data['employee'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<EmployeeModel> updatePermissions(
    String shopId,
    String employeeId,
    List<String> permissions,
  ) async {
    try {
      final res = await _apiClient.dio.put(
        '${_base(shopId)}/$employeeId/permissions',
        data: {'permissions': permissions},
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return EmployeeModel.fromJson(data['employee'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> remove(String shopId, String employeeId) async {
    try {
      await _apiClient.dio.delete('${_base(shopId)}/$employeeId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
