class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final int? telegramChatId;
  final String? telegramUsername;
  final String? googleId;
  final String? balance;
  final String? role;
  final bool isAcceptedPolicy;
  final String? avatarUrl;
  final String? locale;
  final String? createdAt;

  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.telegramChatId,
    this.telegramUsername,
    this.googleId,
    this.balance,
    this.role,
    this.isAcceptedPolicy = false,
    this.avatarUrl,
    this.locale,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      telegramChatId: json['telegram_chat_id'] as int?,
      telegramUsername: json['telegram_username'] as String?,
      googleId: json['google_id'] as String?,
      balance: json['balance']?.toString(),
      role: json['role'] as String?,
      isAcceptedPolicy: json['is_accepted_policy'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      locale: json['locale'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'telegram_chat_id': telegramChatId,
      'telegram_username': telegramUsername,
      'google_id': googleId,
      'balance': balance,
      'role': role,
      'is_accepted_policy': isAcceptedPolicy,
      'avatar_url': avatarUrl,
      'locale': locale,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? role,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone,
      telegramChatId: telegramChatId,
      telegramUsername: telegramUsername,
      googleId: googleId,
      balance: balance,
      role: role ?? this.role,
      isAcceptedPolicy: isAcceptedPolicy,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locale: locale,
      createdAt: createdAt,
    );
  }
}
