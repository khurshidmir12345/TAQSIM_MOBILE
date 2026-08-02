class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String shopId;
  final String name;
  final String? phone;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson({
    required String name,
    String? phone,
    String? note,
  }) {
    return {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (note != null && note.isNotEmpty) 'note': note,
    };
  }

  Map<String, dynamic> toUpdateJson({
    required String name,
    String? phone,
    String? note,
  }) {
    return {
      'name': name,
      'phone': phone,
      if (note != null) 'note': note,
    };
  }
}
