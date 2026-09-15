import '../../../../core/utils/json_numbers.dart';

/// Do'kon bilan jami hisob: berildi − qaytdi − to'landi = qoldiq.
class OutletTotals {
  final double delivered;
  final double returned;
  final double paid;
  final double balance;

  const OutletTotals({
    this.delivered = 0,
    this.returned = 0,
    this.paid = 0,
    this.balance = 0,
  });

  factory OutletTotals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OutletTotals();
    return OutletTotals(
      delivered: jsonDouble(json['delivered']),
      returned: jsonDouble(json['returned']),
      paid: jsonDouble(json['paid']),
      balance: jsonDouble(json['balance']),
    );
  }

  /// Do'kon qarzdor (musbat), oldindan to'lagan (manfiy) yoki teng.
  bool get owes => balance > 0.005;
  bool get prepaid => balance < -0.005;
}

/// Do'kon — mahsulot tarqatiladigan nuqta.
class OutletModel {
  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final List<String> phones;
  final String? note;
  final bool isActive;
  final OutletTotals totals;

  const OutletModel({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.phones = const [],
    this.note,
    this.isActive = true,
    this.totals = const OutletTotals(),
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    final phones = json['phones'];
    return OutletModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      latitude: json['latitude'] == null ? null : jsonDouble(json['latitude']),
      longitude: json['longitude'] == null
          ? null
          : jsonDouble(json['longitude']),
      imageUrl: json['image_url'] as String?,
      phones: phones is List
          ? phones.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      note: json['note'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      totals: OutletTotals.fromJson(json['totals'] as Map<String, dynamic>?),
    );
  }

  OutletModel copyWith({OutletTotals? totals}) => OutletModel(
    id: id,
    name: name,
    address: address,
    latitude: latitude,
    longitude: longitude,
    imageUrl: imageUrl,
    phones: phones,
    note: note,
    isActive: isActive,
    totals: totals ?? this.totals,
  );
}

/// Daftar qatori turi.
enum OutletEntryType {
  delivery,
  returned,
  payment;

  String get apiValue => switch (this) {
    OutletEntryType.delivery => 'delivery',
    OutletEntryType.returned => 'return',
    OutletEntryType.payment => 'payment',
  };

  static OutletEntryType fromApi(String? v) => switch (v) {
    'delivery' => OutletEntryType.delivery,
    'return' => OutletEntryType.returned,
    _ => OutletEntryType.payment,
  };

  bool get hasItems => this != OutletEntryType.payment;
}

class OutletEntryItemModel {
  final String id;
  final String breadCategoryId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  const OutletEntryItemModel({
    required this.id,
    required this.breadCategoryId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OutletEntryItemModel.fromJson(Map<String, dynamic> json) {
    return OutletEntryItemModel(
      id: json['id'] as String,
      breadCategoryId: json['bread_category_id'] as String,
      name: json['name'] as String? ?? '',
      quantity: jsonDouble(json['quantity']),
      unitPrice: jsonDouble(json['unit_price']),
      subtotal: jsonDouble(json['subtotal']),
    );
  }
}

/// Daftar qatori: berildi / qaytdi / to'landi.
class OutletEntryModel {
  final String id;
  final OutletEntryType type;
  final String date;
  final double amount;

  /// Mahsulot berishda darhol to'langan naqd — o'sha delivery qatoriga bog'lanadi.
  final String? relatedEntryId;
  final String? note;
  final List<OutletEntryItemModel> items;
  final DateTime? createdAt;

  const OutletEntryModel({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    this.relatedEntryId,
    this.note,
    this.items = const [],
    this.createdAt,
  });

  bool get isCashOnDelivery =>
      type == OutletEntryType.payment && relatedEntryId != null;

  factory OutletEntryModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final created = json['created_at'] as String?;
    return OutletEntryModel(
      id: json['id'] as String,
      type: OutletEntryType.fromApi(json['type'] as String?),
      date: json['date'] as String? ?? '',
      amount: jsonDouble(json['amount']),
      relatedEntryId: json['related_entry_id'] as String?,
      note: json['note'] as String?,
      items: items is List
          ? items
                .map(
                  (e) =>
                      OutletEntryItemModel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : const [],
      createdAt: created == null ? null : DateTime.tryParse(created)?.toLocal(),
    );
  }
}
