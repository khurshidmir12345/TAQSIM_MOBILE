class ExpenseCategoryOption {
  const ExpenseCategoryOption({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.icon,
  });

  final String id;
  final String name;
  final bool isSystem;
  final String icon;

  factory ExpenseCategoryOption.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryOption(
      id: json['id'] as String,
      name: json['name'] as String,
      isSystem: json['is_system'] as bool? ?? false,
      icon: json['icon'] as String? ?? 'category',
    );
  }
}
