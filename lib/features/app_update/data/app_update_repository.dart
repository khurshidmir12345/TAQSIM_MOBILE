import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/api/api_client.dart';
import '../domain/models/app_update_info.dart';

/// Ilova versiyasini serverdagi (`.env`) versiya bilan solishtiradi.
///
/// Solishtirishning o'zi serverda bajariladi — qoida bitta joyda tursin va
/// ilovaning eski nusxalari ham to'g'ri javob olsin.
class AppUpdateRepository {
  final ApiClient apiClient;

  AppUpdateRepository(this.apiClient);

  Future<AppUpdateInfo> check() async {
    final pkg = await PackageInfo.fromPlatform();
    final version = pkg.buildNumber.isEmpty
        ? pkg.version
        : '${pkg.version}+${pkg.buildNumber}';

    final response = await apiClient.dio.get(
      '/v1/app-version',
      queryParameters: {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'version': version,
      },
      options: Options(
        // Tekshiruv ilovaning ochilishini sekinlashtirmasin.
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );

    final raw = response.data;
    if (raw is! Map) return const AppUpdateInfo.none();

    final data = raw['data'];
    if (data is! Map) return const AppUpdateInfo.none();

    return AppUpdateInfo.fromJson(Map<String, dynamic>.from(data));
  }
}
