import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/api/api_exceptions.dart';

/// 422 javobida `message` doim umumiy ("Ma'lumotlar noto'g'ri"), aniq sabab
/// esa `errors` ichida bo'ladi. Ilgari ilova faqat umumiy matnni ko'rsatib,
/// foydalanuvchini nima xato ekanidan bexabar qoldirardi.
void main() {
  DioException badResponse(Object? body, {int status = 422}) {
    final req = RequestOptions(path: '/v1/auth/reset-password');

    return DioException(
      requestOptions: req,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: req,
        statusCode: status,
        data: body,
      ),
    );
  }

  group('ApiException.fromDioException — 422', () {
    test('maydon xatosi umumiy xabardan ustun turadi', () {
      final e = ApiException.fromDioException(badResponse(const {
        'success': false,
        'message': 'Ma\'lumotlar noto\'g\'ri',
        'errors': {
          'code': ['Tasdiqlash kodi noto\'g\'ri yoki muddati o\'tgan.'],
        },
      }));

      expect(e.message, 'Tasdiqlash kodi noto\'g\'ri yoki muddati o\'tgan.');
      expect(e.statusCode, 422);
    });

    test('bir nechta maydon bo\'lsa birinchisi olinadi', () {
      final e = ApiException.fromDioException(badResponse(const {
        'message': 'Umumiy',
        'errors': {
          'password': ['Parol juda qisqa.'],
          'code': ['Kod xato.'],
        },
      }));

      expect(e.message, 'Parol juda qisqa.');
    });

    test('errors bo\'lmasa umumiy xabar ko\'rsatiladi', () {
      final e = ApiException.fromDioException(badResponse(const {
        'message': 'Hisob bloklangan',
      }));

      expect(e.message, 'Hisob bloklangan');
    });

    test('errors bo\'sh bo\'lsa umumiy xabarga qaytadi', () {
      final e = ApiException.fromDioException(badResponse(const {
        'message': 'Umumiy xabar',
        'errors': <String, dynamic>{},
      }));

      expect(e.message, 'Umumiy xabar');
    });

    test('errors ichidagi bo\'sh ro\'yxat e\'tiborsiz qoldiriladi', () {
      final e = ApiException.fromDioException(badResponse(const {
        'message': 'Umumiy xabar',
        'errors': {'code': <String>[]},
      }));

      expect(e.message, 'Umumiy xabar');
    });

    test('kutilmagan shakl ilovani buzmaydi', () {
      final e = ApiException.fromDioException(badResponse('oddiy matn'));

      expect(e.message, isNotEmpty);
    });

    test('biznes kodi saqlanib qoladi', () {
      final e = ApiException.fromDioException(badResponse(const {
        'message': 'Bloklangan',
        'code': 'account_blocked',
      }, status: 403));

      expect(e.code, 'account_blocked');
      expect(e.isAccountBlocked, isTrue);
    });
  });
}
