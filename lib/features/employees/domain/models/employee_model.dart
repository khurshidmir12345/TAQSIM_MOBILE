/// Bitta xodim (seller) — pivot + user ma'lumotlari.
class EmployeeModel {
  final String id;
  final String name;
  final String? phone;
  final List<String> permissions;
  final String? joinedAt;

  const EmployeeModel({
    required this.id,
    required this.name,
    this.phone,
    this.permissions = const [],
    this.joinedAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      phone: json['phone'] as String?,
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      joinedAt: json['joined_at'] as String?,
    );
  }
}
