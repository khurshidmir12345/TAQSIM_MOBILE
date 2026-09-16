import '../../../../core/utils/json_numbers.dart';

/// Bir kunda (davrda) ishlatilgan xom ashyo — `reports/ingredients`.
class IngredientUsageModel {
  final String from;
  final String to;
  final int productionCount;
  final double totalCost;
  final List<IngredientUsageItem> items;

  const IngredientUsageModel({
    required this.from,
    required this.to,
    required this.productionCount,
    required this.totalCost,
    required this.items,
  });

  bool get isEmpty => items.isEmpty;

  factory IngredientUsageModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? const {};
    final items = json['items'];
    return IngredientUsageModel(
      from: period['from'] as String? ?? '',
      to: period['to'] as String? ?? '',
      productionCount: jsonInt(json['production_count']),
      totalCost: jsonDouble(json['total_cost']),
      items: items is List
          ? items
                .map(
                  (e) =>
                      IngredientUsageItem.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : const [],
    );
  }
}

class IngredientUsageItem {
  final String ingredientId;
  final String name;
  final String unit;
  final bool isFlour;
  final double pricePerUnit;
  final double quantity;
  final double cost;
  final List<IngredientUsageByProduct> byProduct;

  const IngredientUsageItem({
    required this.ingredientId,
    required this.name,
    required this.unit,
    required this.isFlour,
    required this.pricePerUnit,
    required this.quantity,
    required this.cost,
    required this.byProduct,
  });

  factory IngredientUsageItem.fromJson(Map<String, dynamic> json) {
    final bp = json['by_product'];
    return IngredientUsageItem(
      ingredientId: json['ingredient_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      isFlour: json['is_flour'] == true,
      pricePerUnit: jsonDouble(json['price_per_unit']),
      quantity: jsonDouble(json['quantity']),
      cost: jsonDouble(json['cost']),
      byProduct: bp is List
          ? bp
                .map(
                  (e) => IngredientUsageByProduct.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class IngredientUsageByProduct {
  final String name;
  final double quantity;

  const IngredientUsageByProduct({required this.name, required this.quantity});

  factory IngredientUsageByProduct.fromJson(Map<String, dynamic> json) {
    return IngredientUsageByProduct(
      name: json['name'] as String? ?? '',
      quantity: jsonDouble(json['quantity']),
    );
  }
}
