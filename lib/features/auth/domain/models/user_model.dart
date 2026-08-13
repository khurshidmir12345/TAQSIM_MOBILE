class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final int? telegramChatId;
  final String? telegramUsername;
  final String? googleId;
  final String? role;

  /// Global rol: 'owner' yoki 'seller' (har bir API javobida keladi).
  final String? userType;
  final bool isAcceptedPolicy;
  final String? avatarUrl;
  final String? locale;
  final String? createdAt;

  /// Foydalanuvchida parol bormi. Google/Telegram orqali kirganlarda yo'q —
  /// ularda parol o'rnatishda "eski parol" so'ralmaydi.
  final bool hasPassword;

  /// SMS kodi bilan kirgan, lekin parolni hali qo'ymagan. Shu turgan ekan
  /// ilova har kirganda parol o'rnatish ekranini ko'rsatadi.
  final bool mustSetPassword;

  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.telegramChatId,
    this.telegramUsername,
    this.googleId,
    this.role,
    this.userType,
    this.isAcceptedPolicy = false,
    this.avatarUrl,
    this.locale,
    this.createdAt,
    this.hasPassword = true,
    this.mustSetPassword = false,
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
      role: json['role'] as String?,
      userType: json['user_type'] as String?,
      isAcceptedPolicy: json['is_accepted_policy'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      locale: json['locale'] as String?,
      createdAt: json['created_at'] as String?,
      // Eski serverlar bu maydonlarni qaytarmasligi mumkin — parol bor deb
      // hisoblanadi, ya'ni avvalgi xatti-harakat saqlanadi.
      hasPassword: json['has_password'] as bool? ?? true,
      mustSetPassword: json['must_set_password'] as bool? ?? false,
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
      'role': role,
      'user_type': userType,
      'is_accepted_policy': isAcceptedPolicy,
      'avatar_url': avatarUrl,
      'locale': locale,
      'created_at': createdAt,
    };
  }

  /// Joriy foydalanuvchi xodim (seller) ekanligini bildiradi.
  bool get isSeller => userType == 'seller';

  /// Joriy foydalanuvchi biznes egasi (owner) ekanligini bildiradi.
  /// user_type noma'lum bo'lsa — egasi deb hisoblanadi (backend default).
  bool get isOwner => !isSeller;

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? role,
    String? userType,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone,
      telegramChatId: telegramChatId,
      telegramUsername: telegramUsername,
      googleId: googleId,
      role: role ?? this.role,
      userType: userType ?? this.userType,
      isAcceptedPolicy: isAcceptedPolicy,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locale: locale,
      createdAt: createdAt,
    );
  }
}
