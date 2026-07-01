class DeviceModel {
  final String id;
  final String? deviceName;
  final String? platform;
  final String? appVersion;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final bool isCurrent;

  const DeviceModel({
    required this.id,
    this.deviceName,
    this.platform,
    this.appVersion,
    this.lastActiveAt,
    this.createdAt,
    this.isCurrent = false,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'].toString(),
      deviceName: json['device_name'] as String?,
      platform: json['platform'] as String?,
      appVersion: json['app_version'] as String?,
      lastActiveAt: _parseDate(json['last_active_at']),
      createdAt: _parseDate(json['created_at']),
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
