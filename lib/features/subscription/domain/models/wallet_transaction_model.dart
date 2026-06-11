class WalletTransactionModel {
  final String id;
  final String type; // topup | subscription_charge | refund | adjustment
  final double amount;
  final bool isCredit;
  final double balanceAfter;
  final String currencyCode;
  final String? description;
  final String? status;
  final String? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.isCredit,
    required this.balanceAfter,
    required this.currencyCode,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'adjustment',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      isCredit: json['is_credit'] as bool? ?? false,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'UZS',
      description: json['description'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
