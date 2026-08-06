import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/notification_model.dart';

class NotificationsPage {
  final List<NotificationModel> items;
  final int unreadCount;
  final int currentPage;
  final int lastPage;

  const NotificationsPage({
    required this.items,
    required this.unreadCount,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<NotificationsPage> fetch({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/notifications',
        queryParameters: {'page': page},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final list = data['notifications'] as List<dynamic>? ?? const [];
      final meta = data['meta'] as Map<String, dynamic>? ?? const {};

      return NotificationsPage(
        items: list
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
        currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _apiClient.dio.get('/v1/notifications/unread-count');
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> markRead(String id) async {
    try {
      final response = await _apiClient.dio.post('/v1/notifications/$id/read');
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.dio.post('/v1/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _apiClient.dio.delete('/v1/notifications/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<NotificationPreferences> getPreferences() async {
    try {
      final response = await _apiClient.dio.get('/v1/notifications/preferences');
      final data = response.data['data'] as Map<String, dynamic>;
      return NotificationPreferences.fromJson(
        data['preferences'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<NotificationPreferences> updatePreferences(
    Map<String, bool> changes,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '/v1/notifications/preferences',
        data: changes,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return NotificationPreferences.fromJson(
        data['preferences'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// FCM tokenini joriy qurilma sessiyasiga bog'laydi.
  Future<void> registerPushToken(String token, String platform) async {
    try {
      await _apiClient.dio.post(
        '/v1/notifications/push-token',
        data: {'push_token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
