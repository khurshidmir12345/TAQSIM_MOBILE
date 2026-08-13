import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/features/statistics/domain/models/statistics_model.dart';

void main() {
  group('StatisticsModel', () {
    test('serverdan kelgan javob to‘liq o‘qiladi', () {
      final m = StatisticsModel.fromJson(const {
        'series': [
          {
            'date': '2026-08-01',
            'income': 1000000,
            'expense': 900000,
            'profit': 100000,
          },
        ],
        'totals': {
          'income': 1000000,
          'expense': 900000,
          'profit': 100000,
          'ingredient_cost': 600000,
          'external_expenses': 300000,
          'returns': 0,
        },
        'products': [
          {
            'bread_category_id': 'abc',
            'name': 'Somsa',
            'quantity': 200,
            'selling_price': 5000,
            'ingredient_unit_cost': 3000,
            'overhead_unit_cost': 1000,
            'true_unit_cost': 4000,
          },
        ],
      });

      expect(m.series, hasLength(1));
      expect(m.series.first.date, DateTime(2026, 8, 1));
      expect(m.series.first.profit, 100000);

      expect(m.totals.income, 1000000);
      expect(m.totals.ingredientCost, 600000);
      expect(m.totals.externalExpenses, 300000);

      expect(m.products.first.name, 'Somsa');
      expect(m.products.first.trueUnitCost, 4000);
    });

    test('foyda = daromad − xarajat ekanligi serverdan keladi', () {
      // Ilova o‘zi hisoblamaydi — bu qoidani backend belgilaydi, shuning uchun
      // model faqat kelgan qiymatni saqlashi kerak.
      final m = StatisticsModel.fromJson(const {
        'totals': {'income': 500, 'expense': 800, 'profit': -300},
      });

      expect(m.totals.profit, -300);
    });

    test('asl tannarx = xom ashyo + tashqi xarajat ulushi', () {
      final p = ProductTrueCost.fromJson(const {
        'bread_category_id': 'x',
        'name': 'Tort',
        'quantity': 10,
        'selling_price': 50000,
        'ingredient_unit_cost': 20000,
        'overhead_unit_cost': 10000,
        'true_unit_cost': 30000,
      });

      expect(p.trueUnitCost, p.ingredientUnitCost + p.overheadUnitCost);
      // 1 donadan qoladigan foyda — sotuv narxidan asl tannarx ayriladi.
      expect(p.unitProfit, 20000);
    });

    test('bo‘sh javob ilovani buzmaydi', () {
      final m = StatisticsModel.fromJson(const {});

      expect(m.series, isEmpty);
      expect(m.products, isEmpty);
      expect(m.totals.income, 0);
      expect(m.isEmpty, isTrue);
    });

    test('faqat nol qiymatli kunlar bo‘sh deb hisoblanadi', () {
      final m = StatisticsModel.fromJson(const {
        'series': [
          {'date': '2026-08-01', 'income': 0, 'expense': 0, 'profit': 0},
        ],
        'products': [],
      });

      expect(m.isEmpty, isTrue);
    });

    test('ma‘lumot bo‘lsa bo‘sh deb hisoblanmaydi', () {
      final m = StatisticsModel.fromJson(const {
        'series': [
          {'date': '2026-08-01', 'income': 100, 'expense': 0, 'profit': 100},
        ],
      });

      expect(m.isEmpty, isFalse);
    });
  });
}
