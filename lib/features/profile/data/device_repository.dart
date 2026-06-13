import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exceptions.dart';
import '../domain/models/device_model.dart';

class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  Future<List<DeviceModel>> getDevices() async {
    try {
      final response = await _apiClient.dio.get('/v1/auth/devices');
      final data = response.data['data'] as Map<String, dynamic>;
      final list = data['devices'] as List<dynamic>? ?? const [];
      return list
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> revokeDevice(String id) async {
    try {
      await _apiClient.dio.delete('/v1/auth/devices/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
