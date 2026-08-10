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

/// Push sozlamasi — yagona yoqish/o'chirish tugmasi.
///
/// O'chirilganda kunlik tilak va zakaz eslatmalari to'xtaydi. Xodim
/// qo'shilishi va tizim xabarlari muhim, shuning uchun ular baribir keladi —
/// buni server hal qiladi.
class NotificationPreferences {
  final bool enabled;

  const NotificationPreferences({this.enabled = true});

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(enabled: json['enabled'] as bool? ?? true);
  }

  Map<String, bool> toJson() => {'enabled': enabled};

  NotificationPreferences copyWith({bool? enabled}) {
    return NotificationPreferences(enabled: enabled ?? this.enabled);
  }
}
