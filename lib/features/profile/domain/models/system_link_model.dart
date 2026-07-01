/// Mobil ilovaning "Aloqa" bo'limida ko'rsatiladigan tashqi havolalar.
///
/// Backend `GET /api/v1/system-links` faqat `is_active=true` yozuvlarni
/// qaytaradi. Tur nomlari backend `system_links.type` qiymatlariga mos
/// (telegram / instagram / youtube / support, hamda mavjud terms / privacy).
class SystemLinkModel {
  final String type;
  final String name;
  final String url;

  const SystemLinkModel({
    required this.type,
    required this.name,
    required this.url,
  });

  factory SystemLinkModel.fromJson(Map<String, dynamic> json) {
    return SystemLinkModel(
      type: (json['type'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
    );
  }
}
