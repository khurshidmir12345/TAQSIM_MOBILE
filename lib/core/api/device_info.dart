import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_client.dart';

/// Qurilma metama'lumotini aniqlab, [ApiClient] headerlariga yozadi.
/// Backend multi-device sessiya ro'yxati uchun ishlatadi.
class DeviceInfo {
  const DeviceInfo._();

  /// Ilova ishga tushganda bir marta chaqiriladi.
  static Future<void> attachToClient(ApiClient client) async {
    try {
      final deviceName = await _resolveDeviceName();
      final version = await _resolveAppVersion();

      client.setDeviceHeaders(
        deviceName: deviceName,
        platform: _platform(),
        appVersion: version,
      );
    } catch (_) {
      // Qurilma ma'lumoti aniqlanmasa — sessiya baribir ishlayveradi.
    }
  }

  static String _platform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    return 'other';
  }

  static Future<String?> _resolveDeviceName() async {
    final info = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return '${ios.name} - iOS ${ios.systemVersion}';
    }

    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return '${android.manufacturer} ${android.model} - Android ${android.version.release}';
    }

    return null;
  }

  static Future<String?> _resolveAppVersion() async {
    final pkg = await PackageInfo.fromPlatform();
    if (pkg.version.isEmpty) return null;
    return '${pkg.version}+${pkg.buildNumber}';
  }
}
