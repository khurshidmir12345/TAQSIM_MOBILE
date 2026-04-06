class MeasurementUnitModel {
  final String id;
  final String type; // 'ingredient' | 'batch'
  final String code;
  final String icon;
  final String name;
  final String? example;
  final Map<String, String> names;
  final Map<String, String?> examples;
  final int sortOrder;

  const MeasurementUnitModel({
    required this.id,
    required this.type,
    required this.code,
    required this.icon,
    required this.name,
    this.example,
    required this.names,
    required this.examples,
    required this.sortOrder,
  });

  factory MeasurementUnitModel.fromJson(Map<String, dynamic> json) {
    final namesJson = json['names'] as Map<String, dynamic>? ?? {};
    final examplesJson = json['examples'] as Map<String, dynamic>? ?? {};

    return MeasurementUnitModel(
      id: json['id'] as String,
      type: json['type'] as String,
      code: json['code'] as String,
      icon: (json['icon'] as String?) ?? '📦',
      name: (json['name'] as String?) ?? json['code'] as String,
      example: json['example'] as String?,
      names: namesJson.map(
        (k, v) => MapEntry(k, v == null ? '' : v.toString()),
      ),
      examples: examplesJson.map(
        (k, v) => MapEntry(k, v?.toString()),
      ),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isIngredient => type == 'ingredient';
  bool get isBatch      => type == 'batch';

  String localizedName(String locale) {
    if (names.isEmpty) return name;
    return names[locale] ?? names['uz'] ?? name;
  }

  String? localizedExample(String locale) {
    if (examples.isEmpty) return example;
    return examples[locale.startsWith('ru') ? 'ru' : 'uz'] ?? example;
  }
}
