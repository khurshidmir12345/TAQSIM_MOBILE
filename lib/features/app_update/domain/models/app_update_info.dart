/// `/v1/app-version` javobi.
class AppUpdateInfo {
  /// Serverda tekshiruv umuman yoqilganmi (`APP_UPDATE_ENABLED`).
  final bool enabled;

  /// Ilova versiyasi do'kondagidan eskimi.
  final bool updateAvailable;

  /// Do'kondagi eng so'nggi versiya — modalkada ko'rsatiladi.
  final String? latestVersion;

  /// "Yangilash" tugmasi ochadigan manzil. Bo'sh bo'lsa tugma ko'rsatilmaydi.
  final String? storeUrl;

  const AppUpdateInfo({
    required this.enabled,
    required this.updateAvailable,
    this.latestVersion,
    this.storeUrl,
  });

  /// Tekshiruv o'chirilgan yoki javob tushunarsiz — modalka chiqmaydi.
  const AppUpdateInfo.none()
      : enabled = false,
        updateAvailable = false,
        latestVersion = null,
        storeUrl = null;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final storeUrl = json['store_url'] as String?;

    return AppUpdateInfo(
      enabled: json['enabled'] as bool? ?? false,
      updateAvailable: json['update_available'] as bool? ?? false,
      latestVersion: json['latest_version'] as String?,
      storeUrl: (storeUrl != null && storeUrl.isNotEmpty) ? storeUrl : null,
    );
  }
}
