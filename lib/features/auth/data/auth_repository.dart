import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/user_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

class SendCodeResult {
  final bool phoneExists;
  final int expiresIn;
  final String? debugCode;

  const SendCodeResult({
    required this.phoneExists,
    required this.expiresIn,
    this.debugCode,
  });
}

class AuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  AuthRepository(this.apiClient, this._storage);

  Future<SendCodeResult> sendCode(String phone) async {
    try {
      final response =
          await apiClient.dio.post('/v1/auth/send-code', data: {'phone': phone});
      final data = _body(response)['data'] as Map<String, dynamic>;
      return SendCodeResult(
        phoneExists: data['phone_exists'] as bool? ?? false,
        expiresIn: data['expires_in'] as int? ?? 120,
        debugCode: data['debug_code'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<({UserModel user, String token})> register({
    required String name,
    required String phone,
    required String code,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post('/v1/auth/register', data: {
        'name': name,
        'phone': phone,
        'code': code,
        'password': password,
        'password_confirmation': password,
      });

      final data = _body(response)['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      await _saveToken(token);
      apiClient.setToken(token);

      return (user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<({UserModel user, String token})> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post('/v1/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      final data = _body(response)['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      await _saveToken(token);
      apiClient.setToken(token);

      return (user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserModel> me() async {
    try {
      final response = await apiClient.dio.get('/v1/auth/me');
      final data = _body(response)['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? locale,
  }) async {
    try {
      final response = await apiClient.dio.put('/v1/auth/profile', data: {
        'name': ?name,
        'email': ?email,
        'locale': ?locale,
      });
      final data = _body(response)['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });
      final response = await apiClient.dio.post(
        '/v1/auth/avatar',
        data: formData,
      );
      final data = _body(response)['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserModel> deleteAvatar() async {
    try {
      final response = await apiClient.dio.delete('/v1/auth/avatar');
      final data = _body(response)['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.dio.put('/v1/auth/password', data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      });
      final data = _body(response)['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await _saveToken(token);
      apiClient.setToken(token);
      return token;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await apiClient.dio.delete('/v1/auth/account');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
    await _clearToken();
    apiClient.clearToken();
  }

  Future<void> logout() async {
    try {
      await apiClient.dio.post('/v1/auth/logout');
    } catch (_) {}
    await _clearToken();
    apiClient.clearToken();
  }

  Future<void> clearLocalSession() async {
    await _clearToken();
    apiClient.clearToken();
  }

  Future<({String sessionToken, String botUsername, int expiresIn})>
      createTelegramSession() async {
    try {
      final response =
          await apiClient.dio.post('/v1/auth/telegram/session');
      final data = _body(response)['data'] as Map<String, dynamic>;
      return (
        sessionToken: data['session_token'] as String,
        botUsername: data['bot_username'] as String,
        expiresIn: data['expires_in'] as int? ?? 600,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<({String status, String? token, UserModel? user})>
      checkTelegramSession(String sessionToken) async {
    try {
      final response = await apiClient.dio
          .get('/v1/auth/telegram/check/$sessionToken');
      final data = _body(response)['data'] as Map<String, dynamic>;

      final status = data['status'] as String? ?? 'pending';
      final token = data['token'] as String?;
      UserModel? user;

      if (data['user'] != null) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      if (token != null) {
        await _saveToken(token);
        apiClient.setToken(token);
      }

      return (status: status, token: token, user: user);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String?> getSavedToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
