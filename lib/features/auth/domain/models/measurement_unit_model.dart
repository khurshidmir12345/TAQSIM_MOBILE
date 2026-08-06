import '../../../../core/l10n/api_locale_holder.dart';

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

  /// Kartochka / chiqimda qisqa ko‘rinish: API bergan lokalizatsiyalangan
  /// nomdan partiya izohi olib tashlanadi (`Dona (partiya)` → `Dona`,
  /// `KG (partiya)` → `KG`, `Шт. (партия)` → `Шт.`). Qavssiz nomlar
  /// (`Qop`, `Qozon`) o‘zgarishsiz qoladi.
  ///
  /// [locale] berilmasa joriy API tili ([ApiLocaleHolder.code]) ishlatiladi.
  String batchShortLabel([String? locale]) {
    final label = _stripParenthetical(
      localizedName(locale ?? ApiLocaleHolder.code),
    );
    // API nom yubormagan holat — xom kod ekranga chiqmasin.
    return label == code ? _prettifyCode(code) : label;
  }

  /// Joriy API tilidagi qisqa nom.
  String get batchDisplayLabel => batchShortLabel();

  /// `Dona (partiya)` → `Dona`.
  static String _stripParenthetical(String value) {
    final trimmed = value.trim();
    if (!trimmed.endsWith(')')) return trimmed;
    final open = trimmed.lastIndexOf('(');
    if (open <= 0) return trimmed;
    final head = trimmed.substring(0, open).trim();
    return head.isEmpty ? trimmed : head;
  }

  /// So‘nggi himoya: `dona_batch` → `Dona` (pastki chiziq ekranga chiqmaydi).
  static String _prettifyCode(String value) {
    var base = value.endsWith('_batch')
        ? value.substring(0, value.length - '_batch'.length)
        : value;
    base = base.replaceAll('_', ' ').trim();
    if (base.isEmpty) return value;
    if (base.length <= 2) return base.toUpperCase();
    return base[0].toUpperCase() + base.substring(1);
  }

  String localizedName(String locale) {
    if (names.isEmpty) return name;
    return names[locale] ?? names['uz'] ?? name;
  }

  String? localizedExample(String locale) {
    if (examples.isEmpty) return example;
    return examples[locale.startsWith('ru') ? 'ru' : 'uz'] ?? example;
  }
}
