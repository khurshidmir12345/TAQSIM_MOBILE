import 'business_type_model.dart';
import 'currency_model.dart';
import 'measurement_unit_model.dart';

class ShopLocation {
  final double latitude;
  final double longitude;

  const ShopLocation({required this.latitude, required this.longitude});

  factory ShopLocation.fromJson(Map<String, dynamic> json) {
    return ShopLocation(
      latitude:  (json['latitude']  as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class ShopModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? address;
  final String? phone;
  final bool isActive;
  final String? userType;
  final String? createdAt;
  final String? businessTypeId;
  final BusinessTypeModel? businessType;
  final String? currencyId;
  final CurrencyModel? currency;
  final ShopLocation? location;
  final List<MeasurementUnitModel> measurementUnits;
  final String? customBusinessTypeName;

  const ShopModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.address,
    this.phone,
    this.isActive = true,
    this.userType,
    this.createdAt,
    this.businessTypeId,
    this.businessType,
    this.currencyId,
    this.currency,
    this.location,
    this.measurementUnits = const [],
    this.customBusinessTypeName,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    final locJson = json['location'] as Map<String, dynamic>?;
    final btJson  = json['business_type'] as Map<String, dynamic>?;
    final curJson = json['currency'] as Map<String, dynamic>?;

    final unitsJson = json['measurement_units'] as List<dynamic>? ?? [];

    return ShopModel(
      id:             json['id'] as String,
      name:           json['name'] as String,
      slug:           json['slug'] as String,
      description:    json['description'] as String?,
      address:        json['address'] as String?,
      phone:          json['phone'] as String?,
      isActive:       json['is_active'] as bool? ?? true,
      userType:       json['user_type'] as String?,
      createdAt:      json['created_at'] as String?,
      businessTypeId: json['business_type_id'] as String?,
      businessType:   btJson != null ? BusinessTypeModel.fromJson(btJson) : null,
      currencyId:     json['currency_id'] as String?,
      currency:       curJson != null ? CurrencyModel.fromJson(curJson) : null,
      location:       locJson != null ? ShopLocation.fromJson(locJson) : null,
      measurementUnits: unitsJson
          .map((e) => MeasurementUnitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      customBusinessTypeName: json['custom_business_type'] as String?,
    );
  }

  /// Current shop's terminology for [locale].
  BusinessTerminology terminology(String locale) {
    return businessType?.getTerminology(locale) ??
        BusinessTerminology.defaultTerminology;
  }
}
