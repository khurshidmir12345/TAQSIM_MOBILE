import '../../../../core/utils/json_numbers.dart';

class ExpenseModel {
  final String id;
  final String shopId;
  final String category;
  /// API: tizim kaliti yoki maxsus kategoriya UUID; ko‘rsatish uchun.
  final String? categoryLabel;
  final String? description;
  final double amount;
  final String date;
  final String createdBy;
  final String? createdAt;

  const ExpenseModel({
    required this.id,
    required this.shopId,
    required this.category,
    this.categoryLabel,
    this.description,
    required this.amount,
    required this.date,
    required this.createdBy,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      category: json['category'] as String? ?? '',
      categoryLabel: json['category_label'] as String?,
      description: json['description'] as String?,
      amount: jsonDouble(json['amount']),
      date: json['date'] as String,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  /// Kassa / ro‘yxat — API `category_label` yoki eski qiymat.
  String get displayCategoryLabel {
    if (categoryLabel != null && categoryLabel!.trim().isNotEmpty) {
      return categoryLabel!.trim();
    }
    return switch (category) {
      'transport' => 'Transport',
      'kommunal' => 'Kommunal',
      'maosh' => 'Maosh',
      'boshqa' => 'Boshqa',
      _ => category,
    };
  }
}
