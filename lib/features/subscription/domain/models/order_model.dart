class OrderModel {
  final String id;
  final String orderNumber;
  final String type; // subscription | topup
  final String status; // pending | paid | failed | cancelled
  final String? planCode;
  final String? planName;
  final double? amountUsd;
  final double amountLocal;
  final String currencyCode;
  final String? paymentMethod;
  final String? paidAt;
  final String? createdAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.type,
    required this.status,
    required this.planCode,
    required this.planName,
    required this.amountUsd,
    required this.amountLocal,
    required this.currencyCode,
    required this.paymentMethod,
    required this.paidAt,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      type: json['type'] as String? ?? 'subscription',
      status: json['status'] as String? ?? 'pending',
      planCode: json['plan_code'] as String?,
      planName: json['plan_name'] as String?,
      amountUsd: (json['amount_usd'] as num?)?.toDouble(),
      amountLocal: (json['amount_local'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'UZS',
      paymentMethod: json['payment_method'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
