import '../../../../core/utils/json_numbers.dart';

/// Grafikdagi bitta kun.
class StatPoint {
  final DateTime date;
  final double income;
  final double expense;
  final double profit;

  const StatPoint({
    required this.date,
    required this.income,
    required this.expense,
    required this.profit,
  });

  factory StatPoint.fromJson(Map<String, dynamic> json) {
    return StatPoint(
      date: DateTime.parse(json['date'] as String),
      income: jsonDouble(json['income']),
      expense: jsonDouble(json['expense']),
      profit: jsonDouble(json['profit']),
    );
  }
}

/// Davr bo'yicha umumiy summalar.
class StatTotals {
  final double income;
  final double expense;
  final double profit;
  final double ingredientCost;
  final double externalExpenses;
  final double returns;

  const StatTotals({
    this.income = 0,
    this.expense = 0,
    this.profit = 0,
    this.ingredientCost = 0,
    this.externalExpenses = 0,
    this.returns = 0,
  });

  factory StatTotals.fromJson(Map<String, dynamic> json) {
    return StatTotals(
      income: jsonDouble(json['income']),
      expense: jsonDouble(json['expense']),
      profit: jsonDouble(json['profit']),
      ingredientCost: jsonDouble(json['ingredient_cost']),
      externalExpenses: jsonDouble(json['external_expenses']),
      returns: jsonDouble(json['returns']),
    );
  }
}

/// Mahsulotning asl tannarxi.
///
/// [ingredientUnitCost] — hisoblash sahifasidagi tannarx (faqat xom ashyo).
/// [overheadUnitCost]   — shu mahsulotga to'g'ri kelgan tashqi xarajat.
/// [trueUnitCost]       — ikkalasining yig'indisi.
class ProductTrueCost {
  final String id;
  final String name;
  final int quantity;
  final double sellingPrice;
  final double ingredientUnitCost;
  final double overheadUnitCost;
  final double trueUnitCost;

  const ProductTrueCost({
    required this.id,
    required this.name,
    required this.quantity,
    required this.sellingPrice,
    required this.ingredientUnitCost,
    required this.overheadUnitCost,
    required this.trueUnitCost,
  });

  factory ProductTrueCost.fromJson(Map<String, dynamic> json) {
    return ProductTrueCost(
      id: json['bread_category_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: jsonInt(json['quantity']),
      sellingPrice: jsonDouble(json['selling_price']),
      ingredientUnitCost: jsonDouble(json['ingredient_unit_cost']),
      overheadUnitCost: jsonDouble(json['overhead_unit_cost']),
      trueUnitCost: jsonDouble(json['true_unit_cost']),
    );
  }

  /// 1 donadan qoladigan foyda (sotuv narxi − asl tannarx).
  double get unitProfit => sellingPrice - trueUnitCost;
}

class StatisticsModel {
  final List<StatPoint> series;
  final StatTotals totals;
  final List<ProductTrueCost> products;

  const StatisticsModel({
    this.series = const [],
    this.totals = const StatTotals(),
    this.products = const [],
  });

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      series: (json['series'] as List<dynamic>? ?? const [])
          .map((e) => StatPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: StatTotals.fromJson(
        json['totals'] as Map<String, dynamic>? ?? const {},
      ),
      products: (json['products'] as List<dynamic>? ?? const [])
          .map((e) => ProductTrueCost.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty =>
      series.every((p) => p.income == 0 && p.expense == 0) && products.isEmpty;
}
