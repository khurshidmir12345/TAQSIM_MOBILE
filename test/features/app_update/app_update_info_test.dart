import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/features/app_update/domain/models/app_update_info.dart';

void main() {
  group('AppUpdateInfo', () {
    test('yangilanish bor javobi to‘liq o‘qiladi', () {
      final info = AppUpdateInfo.fromJson(const {
        'enabled': true,
        'update_available': true,
        'latest_version': '1.2.8',
        'store_url': 'https://play.google.com/store/apps/details?id=uz.taqseem.mobile',
        'platform': 'android',
        'current_version': '1.2.7',
      });

      expect(info.updateAvailable, isTrue);
      expect(info.latestVersion, '1.2.8');
      expect(info.storeUrl, isNotNull);
    });

    test('serverda o‘chirilgan bo‘lsa modalka chiqmaydi', () {
      final info = AppUpdateInfo.fromJson(const {
        'enabled': false,
        'update_available': false,
        'latest_version': '9.9.9',
        'store_url': null,
      });

      expect(info.enabled, isFalse);
      expect(info.updateAvailable, isFalse);
    });

    test('maydonlar yetishmasa modalka chiqmaydi', () {
      // Eski yoki buzuq javob tufayli modalka chiqib qolmasligi kerak.
      final info = AppUpdateInfo.fromJson(const {});

      expect(info.updateAvailable, isFalse);
      expect(info.latestVersion, isNull);
      expect(info.storeUrl, isNull);
    });

    test('bo‘sh do‘kon manzili yo‘q deb hisoblanadi', () {
      // Manzil bo'sh bo'lsa "Yangilash" tugmasi ko'rsatilmaydi.
      final info = AppUpdateInfo.fromJson(const {
        'enabled': true,
        'update_available': true,
        'latest_version': '1.2.8',
        'store_url': '',
      });

      expect(info.updateAvailable, isTrue);
      expect(info.storeUrl, isNull);
    });
  });
}
