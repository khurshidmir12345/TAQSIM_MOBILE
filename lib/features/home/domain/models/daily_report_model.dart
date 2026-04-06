import '../../../../core/utils/json_numbers.dart';

class DailyReportModel {
  final ReportPeriod period;
  final ReportProduction production;
  final ReportSales sales;
  final ReportReturns returns;
  final double netSales;
  final ReportExpenses expenses;
  final double profit;
  final List<ReportReturnByCategory> returnsByCategory;
  final List<ReportProductBreakdown> productBreakdown;

  const DailyReportModel({
    required this.period,
    required this.production,
    required this.sales,
    required this.returns,
    required this.netSales,
    required this.expenses,
    required this.profit,
    this.returnsByCategory = const [],
    this.productBreakdown = const [],
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    final rbc = json['returns_by_category'];
    final pb = json['product_breakdown'];
    return DailyReportModel(
      period: ReportPeriod.fromJson(json['period'] as Map<String, dynamic>),
      production: ReportProduction.fromJson(json['production'] as Map<String, dynamic>),
      sales: ReportSales.fromJson(json['sales'] as Map<String, dynamic>),
      returns: ReportReturns.fromJson(json['returns'] as Map<String, dynamic>),
      netSales: jsonDouble(json['net_sales']),
      expenses: ReportExpenses.fromJson(json['expenses'] as Map<String, dynamic>),
      profit: jsonDouble(json['profit']),
      returnsByCategory: rbc is List
          ? rbc
              .map((e) => ReportReturnByCategory.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      productBreakdown: pb is List
          ? pb
              .map((e) => ReportProductBreakdown.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

class ReportReturnByCategory {
  final String breadCategoryId;
  final String name;
  final int quantity;
  final double totalAmount;
  final int count;

  const ReportReturnByCategory({
    required this.breadCategoryId,
    required this.name,
    required this.quantity,
    required this.totalAmount,
    required this.count,
  });

  factory ReportReturnByCategory.fromJson(Map<String, dynamic> json) {
    return ReportReturnByCategory(
      breadCategoryId: json['bread_category_id'] as String,
      name: json['name'] as String? ?? '',
      quantity: jsonInt(json['quantity']),
      totalAmount: jsonDouble(json['total_amount']),
      count: jsonInt(json['count']),
    );
  }
}

class ReportProductBreakdown {
  final String breadCategoryId;
  final String name;
  final int totalProduced;
  final double grossRevenue;
  final double ingredientCost;
  final int returnsQuantity;
  final double returnsAmount;
  final double netRevenue;
  final double profit;

  const ReportProductBreakdown({
    required this.breadCategoryId,
    required this.name,
    required this.totalProduced,
    required this.grossRevenue,
    required this.ingredientCost,
    required this.returnsQuantity,
    required this.returnsAmount,
    required this.netRevenue,
    required this.profit,
  });

  factory ReportProductBreakdown.fromJson(Map<String, dynamic> json) {
    return ReportProductBreakdown(
      breadCategoryId: json['bread_category_id'] as String,
      name: json['name'] as String? ?? '',
      totalProduced: jsonInt(json['total_produced']),
      grossRevenue: jsonDouble(json['gross_revenue']),
      ingredientCost: jsonDouble(json['ingredient_cost']),
      returnsQuantity: jsonInt(json['returns_quantity']),
      returnsAmount: jsonDouble(json['returns_amount']),
      netRevenue: jsonDouble(json['net_revenue']),
      profit: jsonDouble(json['profit']),
    );
  }
}

class ReportPeriod {
  final String from;
  final String to;

  const ReportPeriod({required this.from, required this.to});

  factory ReportPeriod.fromJson(Map<String, dynamic> json) {
    return ReportPeriod(
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }
}

class ReportProduction {
  final double totalFlourKg;
  final int totalBread;
  final double ingredientCost;
  final int count;

  const ReportProduction({
    required this.totalFlourKg,
    required this.totalBread,
    required this.ingredientCost,
    required this.count,
  });

  factory ReportProduction.fromJson(Map<String, dynamic> json) {
    return ReportProduction(
      totalFlourKg: jsonDouble(json['total_flour_kg']),
      totalBread: jsonInt(json['total_bread']),
      ingredientCost: jsonDouble(json['ingredient_cost']),
      count: jsonInt(json['count']),
    );
  }
}

class ReportSales {
  final int totalQuantity;
  /// Netto tushum (vozvratdan keyin). Backend `sales.total_amount`.
  final double totalAmount;
  /// Brutto (chiqim × narx yig‘indisi), agar API yuborsa.
  final double? grossAmount;

  const ReportSales({
    required this.totalQuantity,
    required this.totalAmount,
    this.grossAmount,
  });

  factory ReportSales.fromJson(Map<String, dynamic> json) {
    return ReportSales(
      totalQuantity: jsonInt(json['total_quantity']),
      totalAmount: jsonDouble(json['total_amount']),
      grossAmount: json['gross_amount'] != null
          ? jsonDouble(json['gross_amount'])
          : null,
    );
  }
}

class ReportReturns {
  final int totalQuantity;
  final double totalAmount;
  final int count;

  const ReportReturns({
    required this.totalQuantity,
    required this.totalAmount,
    required this.count,
  });

  factory ReportReturns.fromJson(Map<String, dynamic> json) {
    return ReportReturns(
      totalQuantity: jsonInt(json['total_quantity']),
      totalAmount: jsonDouble(json['total_amount']),
      count: jsonInt(json['count']),
    );
  }
}

class ReportExpenses {
  final double ingredientCost;
  final double external;
  final double total;
  final Map<String, double> byCategory;

  const ReportExpenses({
    required this.ingredientCost,
    required this.external,
    required this.total,
    this.byCategory = const {},
  });

  factory ReportExpenses.fromJson(Map<String, dynamic> json) {
    // API ba'zan bo'sh `by_category` ni JSON massiv [] qilib yuboradi (PHP assoc []).
    final byCat = _parseExpenseByCategory(json['by_category']);

    return ReportExpenses(
      ingredientCost: jsonDouble(json['ingredient_cost']),
      external: jsonDouble(json['external']),
      total: jsonDouble(json['total']),
      byCategory: byCat,
    );
  }
}

Map<String, double> _parseExpenseByCategory(dynamic raw) {
  if (raw == null) return {};
  if (raw is Map) {
    return raw.map(
      (k, v) => MapEntry(k.toString(), jsonDouble(v)),
    );
  }
  if (raw is List) return {};
  return {};
}
