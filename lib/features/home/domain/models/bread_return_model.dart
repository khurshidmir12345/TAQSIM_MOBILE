import '../../../../core/utils/json_numbers.dart';
import '../../../setup/domain/models/bread_category_model.dart';

/// API dagi `production` obyektining qisqa ko‘rinishi.
class BreadReturnProductionSummary {
  final String id;
  final double batchCount;
  final int breadProduced;
  final String date;

  const BreadReturnProductionSummary({
    required this.id,
    required this.batchCount,
    required this.breadProduced,
    required this.date,
  });

  factory BreadReturnProductionSummary.fromJson(Map<String, dynamic> json) {
    return BreadReturnProductionSummary(
      id: json['id'] as String,
      batchCount: jsonDouble(json['batch_count']),
      breadProduced: jsonInt(json['bread_produced']),
      date: json['date'] as String,
    );
  }
}

class BreadReturnModel {
  final String id;
  final String shopId;
  final String breadCategoryId;
  final String? productionId;
  final String date;
  final int quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String? reason;
  final String createdBy;
  final BreadCategoryModel? breadCategory;
  final String? createdAt;
  final BreadReturnProductionSummary? productionSummary;

  const BreadReturnModel({
    required this.id,
    required this.shopId,
    required this.breadCategoryId,
    this.productionId,
    required this.date,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    this.reason,
    required this.createdBy,
    this.breadCategory,
    this.createdAt,
    this.productionSummary,
  });

  factory BreadReturnModel.fromJson(Map<String, dynamic> json) {
    return BreadReturnModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      breadCategoryId: json['bread_category_id'] as String,
      productionId: json['production_id'] as String?,
      date: json['date'] as String,
      quantity: jsonInt(json['quantity']),
      pricePerUnit: jsonDouble(json['price_per_unit']),
      totalAmount: jsonDouble(json['total_amount']),
      reason: json['reason'] as String?,
      // API ba'zi javoblarda created_by yubormasligi mumkin
      createdBy: json['created_by'] as String? ?? '',
      breadCategory: json['bread_category'] != null
          ? BreadCategoryModel.fromJson(json['bread_category'])
          : null,
      createdAt: json['created_at'] as String?,
      productionSummary: json['production'] != null
          ? BreadReturnProductionSummary.fromJson(
              json['production'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
