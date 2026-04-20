import '../../../../core/utils/json_numbers.dart';
import '../../../setup/domain/models/bread_category_model.dart';
import '../../../setup/domain/models/recipe_model.dart';

class ProductionModel {
  final String id;
  final String shopId;
  final String recipeId;
  final String breadCategoryId;
  final String date;
  final double batchCount;
  final double? flourUsedKg;
  final int breadProduced;
  final double ingredientCost;
  final String? notes;
  final String createdBy;
  final BreadCategoryModel? breadCategory;
  final RecipeModel? recipe;
  final String? createdAt;

  /// Backend: shu tur bo‘yicha vozvrat summasining ushbu partiyaga ulushi.
  final double returnsAmount;
  final int returnsQuantityAllocated;
  /// Brutto tushum (chiqim × narx).
  final double grossRevenue;
  /// Netto tushum (brutto − returns_amount).
  final double netRevenue;
  /// Netto foyda (net_revenue − ingredient_cost).
  final double netProfit;

  const ProductionModel({
    required this.id,
    required this.shopId,
    required this.recipeId,
    required this.breadCategoryId,
    required this.date,
    required this.batchCount,
    this.flourUsedKg,
    required this.breadProduced,
    required this.ingredientCost,
    this.notes,
    required this.createdBy,
    this.breadCategory,
    this.recipe,
    this.createdAt,
    this.returnsAmount = 0,
    this.returnsQuantityAllocated = 0,
    this.grossRevenue = 0,
    this.netRevenue = 0,
    this.netProfit = 0,
  });

  factory ProductionModel.fromJson(Map<String, dynamic> json) {
    final breadCategory = json['bread_category'] != null
        ? BreadCategoryModel.fromJson(
            json['bread_category'] as Map<String, dynamic>,
          )
        : null;
    final breadProduced = jsonInt(json['bread_produced']);
    final price =
        double.tryParse(breadCategory?.sellingPrice ?? '0') ?? 0;
    final fallbackGross = breadProduced * price;
    final ingredientCost = jsonDouble(json['ingredient_cost']);
    final ra = jsonDouble(json['returns_amount'] ?? 0);
    final gross = json['gross_revenue'] != null
        ? jsonDouble(json['gross_revenue'])
        : fallbackGross;
    final netRev = json['net_revenue'] != null
        ? jsonDouble(json['net_revenue'])
        : (gross - ra);
    final netPf = json['net_profit'] != null
        ? jsonDouble(json['net_profit'])
        : (netRev - ingredientCost);

    return ProductionModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      recipeId: json['recipe_id'] as String,
      breadCategoryId: json['bread_category_id'] as String,
      date: json['date'] as String,
      batchCount: jsonDouble(json['batch_count']),
      flourUsedKg: json['flour_used_kg'] != null
          ? jsonDouble(json['flour_used_kg'])
          : null,
      breadProduced: breadProduced,
      ingredientCost: ingredientCost,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      breadCategory: breadCategory,
      recipe: json['recipe'] != null
          ? RecipeModel.fromJson(json['recipe'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
      returnsAmount: ra,
      returnsQuantityAllocated:
          jsonInt(json['returns_quantity_allocated'] ?? 0),
      grossRevenue: gross,
      netRevenue: netRev,
      netProfit: netPf,
    );
  }

  double get sellingAmount => grossRevenue;
}
