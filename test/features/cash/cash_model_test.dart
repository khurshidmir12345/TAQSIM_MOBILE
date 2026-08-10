import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/features/cash/domain/models/cash_model.dart';

void main() {
  group('CashEntry', () {
    test('avtomatik yozuv tahrirlanmaydi deb belgilanadi', () {
      final entry = CashEntry.fromJson(const {
        'id': 'x',
        'type': 'expense',
        'source': 'return',
        'category': 'return',
        'category_name': 'Vozvrat',
        'amount': 50000,
        'date': '2026-08-10',
        'is_editable': false,
      });

      expect(entry.source, CashSource.breadReturn);
      expect(entry.isEditable, isFalse);
      expect(entry.isIncome, isFalse);
    });

    test('qo\'lda kirim tahrirlanadi', () {
      final entry = CashEntry.fromJson(const {
        'id': 'y',
        'type': 'income',
        'source': 'manual',
        'category': 'sotuv',
        'category_name': 'Sotuv',
        'amount': '75000.00',
        'date': '2026-08-10',
        'is_editable': true,
      });

      expect(entry.isIncome, isTrue);
      expect(entry.isEditable, isTrue);
      // Server summani matn sifatida qaytarishi mumkin.
      expect(entry.amount, 75000);
    });

    test('yetishmayotgan maydonlar ilovani buzmaydi', () {
      final entry = CashEntry.fromJson(const {'id': 'z'});

      expect(entry.source, CashSource.manual);
      expect(entry.amount, 0);
      expect(entry.categoryName, '');
    });
  });

  group('CashSummary', () {
    test('sof natija va foyda holati o\'qiladi', () {
      final summary = CashSummary.fromJson(const {
        'income': {'total': 500000, 'count': 2, 'by_category': {}},
        'expense': {'total': 350000, 'count': 3, 'by_category': {}},
        'net': 150000,
      });

      expect(summary.income, 500000);
      expect(summary.expense, 350000);
      expect(summary.net, 150000);
      expect(summary.isProfit, isTrue);
      expect(summary.isEmpty, isFalse);
    });

    test('zarar manfiy sof natija bilan ko\'rsatiladi', () {
      final summary = CashSummary.fromJson(const {
        'income': {'total': 50000, 'count': 1},
        'expense': {'total': 200000, 'count': 1},
        'net': -150000,
      });

      expect(summary.isProfit, isFalse);
      expect(summary.net, -150000);
    });

    test('bo\'sh kesim xatosiz o\'qiladi', () {
      // Server bo'sh kategoriya kesimini `{}` qaytaradi.
      final summary = CashSummary.fromJson(const {
        'income': {'total': 0, 'count': 0, 'by_category': {}},
        'expense': {'total': 0, 'count': 0, 'by_category': {}},
        'net': 0,
      });

      expect(summary.isEmpty, isTrue);
      expect(summary.incomeByCategory, isEmpty);
    });

    test('kategoriya kesimi raqamga aylantiriladi', () {
      final summary = CashSummary.fromJson(const {
        'income': {'total': 0, 'count': 0},
        'expense': {
          'total': 90000,
          'count': 2,
          'by_category': {'ijara': '60000.00', 'gaz': 30000},
        },
        'net': -90000,
      });

      expect(summary.expenseByCategory['ijara'], 60000);
      expect(summary.expenseByCategory['gaz'], 30000);
    });
  });

  group('CashSettings', () {
    test('sozlanmagan bo\'lsa ikkalasi ham yoqiq', () {
      const settings = CashSettings();

      expect(settings.trackProduction, isTrue);
      expect(settings.trackReturns, isTrue);
    });

    test('serverdan kelgan qiymat o\'qiladi', () {
      final settings = CashSettings.fromJson(const {
        'track_production': false,
        'track_returns': true,
      });

      expect(settings.trackProduction, isFalse);
      expect(settings.trackReturns, isTrue);
      expect(settings.copyWith(trackProduction: true).trackProduction, isTrue);
    });
  });

  group('CashPage', () {
    test('to\'liq javob bir marta o\'qiladi', () {
      final page = CashPage.fromJson(const {
        'summary': {
          'income': {'total': 100, 'count': 1},
          'expense': {'total': 40, 'count': 1},
          'net': 60,
        },
        'settings': {'track_production': true, 'track_returns': false},
        'entries': [
          {
            'id': 'a',
            'type': 'income',
            'source': 'manual',
            'category': 'sotuv',
            'category_name': 'Sotuv',
            'amount': 100,
            'date': '2026-08-10',
            'is_editable': true,
          },
        ],
        'meta': {'current_page': 1, 'last_page': 3},
      });

      expect(page.summary.net, 60);
      expect(page.settings.trackReturns, isFalse);
      expect(page.entries, hasLength(1));
      expect(page.hasMore, isTrue);
    });
  });
}
