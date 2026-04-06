import '../../../auth/domain/models/currency_model.dart';

class BreadCategoryModel {
  final String id;
  final String shopId;
  final String name;
  final String sellingPrice;
  final String? currencyId;
  final CurrencyModel? currency;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final String? createdAt;

  const BreadCategoryModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.sellingPrice,
    this.currencyId,
    this.currency,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
  });

  /// Narx yonidagi qisqa yozuv (belgi yoki kod).
  String priceSuffix(String fallback) {
    final sym = currency?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    final code = currency?.code;
    if (code != null && code.isNotEmpty) return code;
    return fallback;
  }

  factory BreadCategoryModel.fromJson(Map<String, dynamic> json) {
    final curJson = json['currency'] as Map<String, dynamic>?;
    return BreadCategoryModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      sellingPrice: json['selling_price'].toString(),
      currencyId: json['currency_id'] as String?,
      currency:
          curJson != null ? CurrencyModel.fromJson(curJson) : null,
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }
}
