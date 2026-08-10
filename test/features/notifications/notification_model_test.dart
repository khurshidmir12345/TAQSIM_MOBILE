import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/features/notifications/domain/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('backenddan kelgan matn o‘zgartirilmasdan olinadi', () {
      // Matn backendda foydalanuvchi tilida yaratiladi — ilova uni tarjima
      // qilmaydi, shundayligicha ko‘rsatadi.
      final model = NotificationModel.fromJson(const {
        'id': 'abc',
        'category': 'order_reminder',
        'title': 'Себестоимость партии',
        'body': 'Завтра у вас есть заказ',
        'is_read': false,
        'created_at': '2026-08-06T09:00:00+00:00',
      });

      expect(model.title, 'Себестоимость партии');
      expect(model.body, 'Завтра у вас есть заказ');
      expect(model.category, 'order_reminder');
      expect(model.isRead, isFalse);
      expect(model.createdAt, isNotNull);
    });

    test('yetishmayotgan maydonlar xavfsiz standart qiymat oladi', () {
      final model = NotificationModel.fromJson(const {'id': 'x'});

      expect(model.title, '');
      expect(model.body, '');
      expect(model.category, 'system');
      expect(model.isRead, isFalse);
      expect(model.createdAt, isNull);
    });

    test('noto‘g‘ri sana ilovani buzmaydi', () {
      final model = NotificationModel.fromJson(const {
        'id': 'x',
        'created_at': 'buzuq-sana',
      });

      expect(model.createdAt, isNull);
    });

    test('copyWith faqat o‘qilgan holatini o‘zgartiradi', () {
      final model = NotificationModel.fromJson(const {
        'id': 'x',
        'title': 'Sarlavha',
        'is_read': false,
      });

      final read = model.copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.title, 'Sarlavha');
      expect(read.id, model.id);
    });
  });

  group('NotificationPreferences', () {
    test('sozlanmagan kalit yoqiq deb hisoblanadi', () {
      // Yangi foydalanuvchida server bo‘sh obyekt qaytaradi — push yoqiq.
      final prefs = NotificationPreferences.fromJson(const {});

      expect(prefs.enabled, isTrue);
    });

    test('serverdan kelgan qiymat o‘qiladi', () {
      final prefs = NotificationPreferences.fromJson(const {'enabled': false});

      expect(prefs.enabled, isFalse);
    });

    test('eski kalitlar e’tiborsiz qoldiriladi', () {
      // Tur bo‘yicha alohida tugma yo‘q — server eski kalitlarni hamon
      // qaytarishi mumkin, lekin ular holatga ta’sir qilmasligi kerak.
      final prefs = NotificationPreferences.fromJson(const {
        'enabled': true,
        'daily_greeting': false,
        'order_reminder': false,
      });

      expect(prefs.enabled, isTrue);
    });

    test('toJson serverdagi kalit nomi bilan mos', () {
      final json = const NotificationPreferences().toJson();

      expect(json.keys.toSet(), {'enabled'});
    });

    test('copyWith holatni almashtiradi', () {
      const prefs = NotificationPreferences();

      expect(prefs.copyWith(enabled: false).enabled, isFalse);
      expect(prefs.copyWith().enabled, isTrue);
    });
  });
}
