import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exceptions.dart';
import '../domain/models/system_link_model.dart';

/// Tizim havolalari (Telegram/Instagram/YouTube/Texnik yordam va h.k.) uchun
/// repository. Backend faqat faol yozuvlarni qaytaradi, mobil ham xuddi shu
/// holatda ishlatadi.
class SystemLinkRepository {
  final ApiClient _apiClient;

  SystemLinkRepository(this._apiClient);

  Future<List<SystemLinkModel>> getAll() async {
    try {
      final response = await _apiClient.dio.get('/v1/system-links');
      final data = response.data['data'] as Map<String, dynamic>;
      final list = data['links'] as List<dynamic>? ?? const [];
      return list
          .map((e) => SystemLinkModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
