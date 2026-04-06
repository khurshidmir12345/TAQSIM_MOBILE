class CurrencyModel {
  final String id;
  final String code;
  final String name;
  final String? symbol;
  final int sortOrder;

  const CurrencyModel({
    required this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.sortOrder = 0,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  String get displayLabel {
    if (symbol != null && symbol!.isNotEmpty) {
      return '$code ($symbol)';
    }
    return code;
  }
}
