class PlanLimits {
  final int? shops;
  final int? products;
  final int? employees;

  const PlanLimits({this.shops, this.products, this.employees});

  factory PlanLimits.fromJson(Map<String, dynamic> json) => PlanLimits(
        shops: (json['shops'] as num?)?.toInt(),
        products: (json['products'] as num?)?.toInt(),
        employees: (json['employees'] as num?)?.toInt(),
      );

  bool get unlimitedProducts => products == null;
  bool get unlimitedShops => shops == null;
}

class SubscriptionPlanModel {
  final String id;
  final String code;
  final String name;
  final double priceUsd;
  final double priceLocal;
  final String currencyCode;
  final String billingPeriod;
  final int durationDays;
  final PlanLimits limits;
  final List<String> extraFeatures;
  final bool isTrial;
  final bool isPopular;
  final String? color;
  final int sortOrder;

  const SubscriptionPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.priceUsd,
    required this.priceLocal,
    required this.currencyCode,
    required this.billingPeriod,
    required this.durationDays,
    required this.limits,
    required this.extraFeatures,
    required this.isTrial,
    required this.isPopular,
    required this.color,
    required this.sortOrder,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String? ?? '',
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 0,
      priceLocal: (json['price_local'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'UZS',
      billingPeriod: json['billing_period'] as String? ?? 'monthly',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
      limits: json['limits'] is Map<String, dynamic>
          ? PlanLimits.fromJson(json['limits'] as Map<String, dynamic>)
          : const PlanLimits(),
      extraFeatures: (json['extra_features'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isTrial: json['is_trial'] as bool? ?? false,
      isPopular: json['is_popular'] as bool? ?? false,
      color: json['color'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
