import '../../../auth/domain/models/currency_model.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';

class IngredientModel {
  final String id;
  final String shopId;
  final String name;
  final String unit;
  final String? measurementUnitId;
  final MeasurementUnitModel? measurementUnit;
  final bool isFlour;
  final String pricePerUnit;
  final String? currencyId;
  final CurrencyModel? currency;
  final int sortOrder;
  final bool isActive;
  final String? createdAt;

  const IngredientModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.unit,
    this.measurementUnitId,
    this.measurementUnit,
    this.isFlour = false,
    required this.pricePerUnit,
    this.currencyId,
    this.currency,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
  });

  String priceSuffix(String fallback) {
    final sym = currency?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    final code = currency?.code;
    if (code != null && code.isNotEmpty) return code;
    return fallback;
  }

  /// Ro‘yxat uchun qisqa birlik (API `unit` maydoni).
  String get unitShortLabel {
    return switch (unit) {
      'kg' => 'kg',
      'gram' => 'g',
      'litr' => 'l',
      'ml' => 'ml',
      'dona' => 'ta',
      'metr' => 'm',
      _ => unit,
    };
  }

  /// Ro‘yxat uchun: DB `code` (qisqartma) yoki `unit` dan chiqarilgan qisqa yozuv.
  String get displayUnitLine {
    final c = measurementUnit?.code;
    if (c != null && c.isNotEmpty) return c;
    return unitShortLabel;
  }

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    final curJson = json['currency'] as Map<String, dynamic>?;
    final muJson = json['measurement_unit'] as Map<String, dynamic>?;
    return IngredientModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      unit: _parseUnit(json['unit']),
      measurementUnitId: json['measurement_unit_id'] as String?,
      measurementUnit: muJson != null
          ? MeasurementUnitModel.fromJson(muJson)
          : null,
      isFlour: json['is_flour'] as bool? ?? false,
      pricePerUnit: json['price_per_unit']?.toString() ?? '0',
      currencyId: json['currency_id'] as String?,
      currency:
          curJson != null ? CurrencyModel.fromJson(curJson) : null,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }

  /// API `unit` ba'zan enum sifatida `{ "value": "litr" }` ko'rinishida kelishi mumkin.
  static String _parseUnit(dynamic v) {
    if (v == null) return 'kg';
    if (v is String) return v;
    if (v is Map) {
      final val = v['value'];
      if (val is String) return val;
    }
    return v.toString();
  }
}
