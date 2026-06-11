import 'subscription_plan_model.dart';

class SubscriptionModel {
  final String id;
  final String status; // trialing | active | grace | expired | cancelled
  final bool isTrial;
  final bool hasFullAccess;
  final bool isReadOnly;
  final bool isBlocked;
  final int daysLeft;
  final int graceDaysLeft;
  final String? startsAt;
  final String? endsAt;
  final String? trialEndsAt;
  final String? graceEndsAt;
  final SubscriptionPlanModel? plan;

  const SubscriptionModel({
    required this.id,
    required this.status,
    required this.isTrial,
    required this.hasFullAccess,
    required this.isReadOnly,
    required this.isBlocked,
    required this.daysLeft,
    required this.graceDaysLeft,
    required this.startsAt,
    required this.endsAt,
    required this.trialEndsAt,
    required this.graceEndsAt,
    required this.plan,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'expired',
      isTrial: json['is_trial'] as bool? ?? false,
      hasFullAccess: json['has_full_access'] as bool? ?? false,
      isReadOnly: json['is_read_only'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      daysLeft: (json['days_left'] as num?)?.toInt() ?? 0,
      graceDaysLeft: (json['grace_days_left'] as num?)?.toInt() ?? 0,
      startsAt: json['starts_at'] as String?,
      endsAt: json['ends_at'] as String?,
      trialEndsAt: json['trial_ends_at'] as String?,
      graceEndsAt: json['grace_ends_at'] as String?,
      plan: json['plan'] is Map<String, dynamic>
          ? SubscriptionPlanModel.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UsageInfo {
  final int? limit;
  final int used;
  final bool unlimited;
  final int? remaining;

  const UsageInfo({
    required this.limit,
    required this.used,
    required this.unlimited,
    required this.remaining,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
        limit: (json['limit'] as num?)?.toInt(),
        used: (json['used'] as num?)?.toInt() ?? 0,
        unlimited: json['unlimited'] as bool? ?? false,
        remaining: (json['remaining'] as num?)?.toInt(),
      );

  static const empty = UsageInfo(
    limit: null,
    used: 0,
    unlimited: true,
    remaining: null,
  );
}

/// `/v1/subscription/me` javobi.
class SubscriptionStatusModel {
  final SubscriptionModel? subscription;
  final UsageInfo shops;
  final UsageInfo products;
  final UsageInfo employees;
  final double balance;
  final String currencyCode;

  const SubscriptionStatusModel({
    required this.subscription,
    required this.shops,
    required this.products,
    required this.employees,
    required this.balance,
    required this.currencyCode,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>? ?? {};
    UsageInfo usageOf(String key) => usage[key] is Map<String, dynamic>
        ? UsageInfo.fromJson(usage[key] as Map<String, dynamic>)
        : UsageInfo.empty;

    return SubscriptionStatusModel(
      subscription: json['subscription'] is Map<String, dynamic>
          ? SubscriptionModel.fromJson(
              json['subscription'] as Map<String, dynamic>)
          : null,
      shops: usageOf('shops'),
      products: usageOf('products'),
      employees: usageOf('employees'),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'UZS',
    );
  }

  bool get needsPaywall =>
      subscription == null ? false : subscription!.isBlocked;
}
