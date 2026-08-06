/// Ilova ichidagi bildirishnoma (Profil → Bildirishnomalar).
class NotificationModel {
  final String id;
  final String category;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] as String?;

    return NotificationModel(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: created == null ? null : DateTime.tryParse(created)?.toLocal(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      category: category,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// Push sozlamalari — turlar bo'yicha yoqish/o'chirish.
class NotificationPreferences {
  /// Umumiy tugma — o'chirilsa hech qanday push kelmaydi.
  final bool enabled;
  final bool dailyGreeting;
  final bool orderReminder;
  final bool employeeAdded;
  final bool system;

  const NotificationPreferences({
    this.enabled = true,
    this.dailyGreeting = true,
    this.orderReminder = true,
    this.employeeAdded = true,
    this.system = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    bool read(String key) => json[key] as bool? ?? true;

    return NotificationPreferences(
      enabled: read('enabled'),
      dailyGreeting: read('daily_greeting'),
      orderReminder: read('order_reminder'),
      employeeAdded: read('employee_added'),
      system: read('system'),
    );
  }

  Map<String, bool> toJson() => {
        'enabled': enabled,
        'daily_greeting': dailyGreeting,
        'order_reminder': orderReminder,
        'employee_added': employeeAdded,
        'system': system,
      };

  NotificationPreferences copyWith({
    bool? enabled,
    bool? dailyGreeting,
    bool? orderReminder,
    bool? employeeAdded,
    bool? system,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      dailyGreeting: dailyGreeting ?? this.dailyGreeting,
      orderReminder: orderReminder ?? this.orderReminder,
      employeeAdded: employeeAdded ?? this.employeeAdded,
      system: system ?? this.system,
    );
  }
}
