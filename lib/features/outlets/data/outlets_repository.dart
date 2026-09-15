import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/models/outlet_model.dart';

Map<String, dynamic> _body(Response response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
  throw ApiException.invalidResponse();
}

/// Bitta mahsulot qatori — berish/qaytarish so'rovi uchun.
typedef OutletItemInput = ({
  String breadCategoryId,
  double quantity,
  double? unitPrice,
});

/// Do'konlar va ular bilan hisob-kitob API'si.
class OutletsRepository {
  OutletsRepository(this._api);

  final ApiClient _api;

  String _path(String shopId) => '/v1/shops/$shopId/outlets';

  Future<List<OutletModel>> list(String shopId) async {
    try {
      final res = await _api.dio.get(_path(shopId));
      final data = _body(res)['data'] as Map<String, dynamic>;
      return (data['outlets'] as List)
          .map((e) => OutletModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<OutletModel> get(String shopId, String id) async {
    try {
      final res = await _api.dio.get('${_path(shopId)}/$id');
      final data = _body(res)['data'] as Map<String, dynamic>;
      return OutletModel.fromJson(data['outlet'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Map<String, dynamic> _form({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? phones,
    String? note,
  }) => {
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'phones': phones ?? const <String>[],
    'note': note,
  };

  Future<OutletModel> create(
    String shopId, {
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? phones,
    String? note,
  }) async {
    try {
      final res = await _api.dio.post(
        _path(shopId),
        data: _form(
          name: name,
          address: address,
          latitude: latitude,
          longitude: longitude,
          phones: phones,
          note: note,
        ),
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return OutletModel.fromJson(data['outlet'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<OutletModel> update(
    String shopId,
    String id, {
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? phones,
    String? note,
  }) async {
    try {
      final res = await _api.dio.put(
        '${_path(shopId)}/$id',
        data: _form(
          name: name,
          address: address,
          latitude: latitude,
          longitude: longitude,
          phones: phones,
          note: note,
        ),
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return OutletModel.fromJson(data['outlet'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String shopId, String id) async {
    try {
      await _api.dio.delete('${_path(shopId)}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<OutletModel> uploadImage(
    String shopId,
    String id,
    String filePath,
  ) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final res = await _api.dio.post('${_path(shopId)}/$id/image', data: form);
      final data = _body(res)['data'] as Map<String, dynamic>;
      return OutletModel.fromJson(data['outlet'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<OutletModel> deleteImage(String shopId, String id) async {
    try {
      final res = await _api.dio.delete('${_path(shopId)}/$id/image');
      final data = _body(res)['data'] as Map<String, dynamic>;
      return OutletModel.fromJson(data['outlet'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Daftar: (outlet with fresh totals, entries).
  Future<(OutletModel, List<OutletEntryModel>)> entries(
    String shopId,
    String id, {
    String? from,
    String? to,
  }) async {
    try {
      final res = await _api.dio.get(
        '${_path(shopId)}/$id/entries',
        queryParameters: {'from': ?from, 'to': ?to},
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      final outlet = OutletModel.fromJson(
        data['outlet'] as Map<String, dynamic>,
      );
      final list = (data['entries'] as List)
          .map((e) => OutletEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (outlet, list);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<(OutletModel, OutletEntryModel)> createEntry(
    String shopId,
    String id, {
    required OutletEntryType type,
    required String date,
    List<OutletItemInput> items = const [],
    double? amount,
    double? paidAmount,
    String? note,
  }) async {
    try {
      final res = await _api.dio.post(
        '${_path(shopId)}/$id/entries',
        data: {
          'type': type.apiValue,
          'date': date,
          'note': note,
          if (type.hasItems)
            'items': [
              for (final i in items)
                {
                  'bread_category_id': i.breadCategoryId,
                  'quantity': i.quantity,
                  'unit_price': i.unitPrice,
                },
            ],
          if (!type.hasItems) 'amount': amount,
          if (type == OutletEntryType.delivery && paidAmount != null)
            'paid_amount': paidAmount,
        },
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return (
        OutletModel.fromJson(data['outlet'] as Map<String, dynamic>),
        OutletEntryModel.fromJson(data['entry'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<OutletModel> deleteEntry(
    String shopId,
    String id,
    String entryId,
  ) async {
    try {
      final res = await _api.dio.delete(
        '${_path(shopId)}/$id/entries/$entryId',
      );
      final data = _body(res)['data'] as Map<String, dynamic>;
      return OutletModel.fromJson(data['outlet'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
