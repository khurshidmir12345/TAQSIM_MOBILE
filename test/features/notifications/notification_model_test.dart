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
    test('sozlanmagan kalitlar yoqiq deb hisoblanadi', () {
      // Yangi foydalanuvchida server bo‘sh obyekt qaytaradi — hammasi yoqiq.
      final prefs = NotificationPreferences.fromJson(const {});

      expect(prefs.enabled, isTrue);
      expect(prefs.dailyGreeting, isTrue);
      expect(prefs.orderReminder, isTrue);
      expect(prefs.employeeAdded, isTrue);
      expect(prefs.system, isTrue);
    });

    test('serverdan kelgan qiymatlar o‘qiladi', () {
      final prefs = NotificationPreferences.fromJson(const {
        'enabled': true,
        'daily_greeting': false,
        'order_reminder': true,
      });

      expect(prefs.enabled, isTrue);
      expect(prefs.dailyGreeting, isFalse);
      expect(prefs.orderReminder, isTrue);
      // Kelmagan kalit yoqiq bo‘lib qoladi.
      expect(prefs.system, isTrue);
    });

    test('toJson serverdagi kalit nomlari bilan mos', () {
      final json = const NotificationPreferences().toJson();

      expect(
        json.keys.toSet(),
        {
          'enabled',
          'daily_greeting',
          'order_reminder',
          'employee_added',
          'system',
        },
      );
    });

    test('copyWith bitta maydonni o‘zgartiradi, qolganini saqlaydi', () {
      const prefs = NotificationPreferences();
      final updated = prefs.copyWith(dailyGreeting: false);

      expect(updated.dailyGreeting, isFalse);
      expect(updated.enabled, isTrue);
      expect(updated.orderReminder, isTrue);
    });
  });
}
