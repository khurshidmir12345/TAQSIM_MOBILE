import '../../../../core/utils/json_numbers.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import 'bread_category_model.dart';
import 'ingredient_model.dart';

class RecipeIngredientModel {
  final String id;
  final String ingredientId;
  final IngredientModel? ingredient;
  final String quantity;
  final String? lineCost;

  const RecipeIngredientModel({
    required this.id,
    required this.ingredientId,
    this.ingredient,
    required this.quantity,
    this.lineCost,
  });

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientModel(
      id: json['id'] as String,
      ingredientId: json['ingredient_id'] as String,
      ingredient: json['ingredient'] != null
          ? IngredientModel.fromJson(json['ingredient'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'].toString(),
      lineCost: json['line_cost']?.toString(),
    );
  }
}

class RecipeModel {
  final String id;
  final String shopId;
  final String name;
  final BreadCategoryModel? breadCategory;
  final MeasurementUnitModel? measurementUnit;
  final int outputQuantity;
  final bool isActive;
  final List<RecipeIngredientModel> ingredients;
  final String? totalCost;
  final String? costPerBread;
  final String? flourPerBatch;
  final String? createdAt;

  const RecipeModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.breadCategory,
    this.measurementUnit,
    required this.outputQuantity,
    this.isActive = true,
    this.ingredients = const [],
    this.totalCost,
    this.costPerBread,
    this.flourPerBatch,
    this.createdAt,
  });

  String get productDisplayName => breadCategory?.name ?? name;

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final bcJson = json['bread_category'] as Map<String, dynamic>?;
    final muJson = json['measurement_unit'] as Map<String, dynamic>?;

    return RecipeModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      breadCategory:
          bcJson != null ? BreadCategoryModel.fromJson(bcJson) : null,
      measurementUnit:
          muJson != null ? MeasurementUnitModel.fromJson(muJson) : null,
      outputQuantity: jsonInt(json['output_quantity']),
      isActive: json['is_active'] as bool? ?? true,
      ingredients: (json['ingredients'] as List?)
              ?.map((e) =>
                  RecipeIngredientModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalCost: json['total_cost']?.toString(),
      costPerBread: json['cost_per_bread']?.toString(),
      flourPerBatch: json['flour_per_batch']?.toString(),
      createdAt: json['created_at'] as String?,
    );
  }
}
