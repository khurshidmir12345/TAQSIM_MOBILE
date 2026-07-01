/// Bitta xodim (seller) — pivot + user ma'lumotlari.
class EmployeeModel {
  final String id;
  final String name;
  final String? phone;
  final List<String> permissions;
  final bool isPaidSeat;
  final String? seatStatus; // active | past_due
  final String? seatEndsAt;
  final bool isSuspended;
  final String? joinedAt;

  const EmployeeModel({
    required this.id,
    required this.name,
    this.phone,
    this.permissions = const [],
    this.isPaidSeat = false,
    this.seatStatus,
    this.seatEndsAt,
    this.isSuspended = false,
    this.joinedAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      phone: json['phone'] as String?,
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isPaidSeat: json['is_paid_seat'] as bool? ?? false,
      seatStatus: json['seat_status'] as String?,
      seatEndsAt: json['seat_ends_at'] as String?,
      isSuspended: json['is_suspended'] as bool? ?? false,
      joinedAt: json['joined_at'] as String?,
    );
  }
}

/// Xodimlar bo'limidagi limit/narx meta ma'lumotlari.
class EmployeesMeta {
  final int? limit;
  final int used;
  final bool unlimited;
  final int? remaining;
  final bool hasFreeSlot;
  final double seatPriceUsd;
  final double seatPriceLocal;
  final double basePriceUsd;
  final bool fridayDiscount;
  final int fridayDiscountPercent;

  const EmployeesMeta({
    this.limit,
    this.used = 0,
    this.unlimited = false,
    this.remaining,
    this.hasFreeSlot = true,
    this.seatPriceUsd = 0,
    this.seatPriceLocal = 0,
    this.basePriceUsd = 0,
    this.fridayDiscount = false,
    this.fridayDiscountPercent = 0,
  });

  factory EmployeesMeta.fromJson(Map<String, dynamic> json) {
    final limitInfo = (json['limit'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EmployeesMeta(
      limit: limitInfo['limit'] as int?,
      used: limitInfo['used'] as int? ?? 0,
      unlimited: limitInfo['unlimited'] as bool? ?? false,
      remaining: limitInfo['remaining'] as int?,
      hasFreeSlot: json['has_free_slot'] as bool? ?? true,
      seatPriceUsd: (json['seat_price_usd'] as num?)?.toDouble() ?? 0,
      seatPriceLocal: (json['seat_price_local'] as num?)?.toDouble() ?? 0,
      basePriceUsd: (json['base_price_usd'] as num?)?.toDouble() ?? 0,
      fridayDiscount: json['friday_discount'] as bool? ?? false,
      fridayDiscountPercent: json['friday_discount_percent'] as int? ?? 0,
    );
  }
}

/// "Xodim qo'shish" boshlagandan keyingi javob (kod yuborildi).
class EmployeeInviteResult {
  final String phone;
  final bool isPaid;
  final double priceUsd;
  final double priceLocal;
  final bool fridayDiscount;

  const EmployeeInviteResult({
    required this.phone,
    required this.isPaid,
    required this.priceUsd,
    required this.priceLocal,
    required this.fridayDiscount,
  });

  factory EmployeeInviteResult.fromJson(Map<String, dynamic> json) {
    return EmployeeInviteResult(
      phone: json['phone'] as String? ?? '',
      isPaid: json['is_paid'] as bool? ?? false,
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 0,
      priceLocal: (json['price_local'] as num?)?.toDouble() ?? 0,
      fridayDiscount: json['friday_discount'] as bool? ?? false,
    );
  }
}
