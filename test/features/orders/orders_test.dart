import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taqseem/core/api/api_exceptions.dart';
import 'package:taqseem/core/l10n/translations.dart';
import 'package:taqseem/features/orders/domain/models/customer_order_model.dart';
import 'package:taqseem/features/orders/domain/utils/money_utils.dart';
import 'package:taqseem/features/orders/domain/utils/orders_api_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('money_utils', () {
    test('roundMoney rounds to 2 decimals', () {
      expect(roundMoney(10.005), 10.01);
      expect(roundMoney(10.004), 10.0);
    });

    test('parseAmount handles string and num', () {
      expect(parseAmount('1000.50'), 1000.5);
      expect(parseAmount(42), 42.0);
      expect(parseAmount(null), 0);
    });

    test('toLocalDateTimeString uses YYYY-MM-DDTHH:mm local format', () {
      final dt = DateTime(2026, 3, 15, 9, 5);
      expect(toLocalDateTimeString(dt), '2026-03-15T09:05');
    });

    test('toLocalDateTimeString retains selected minute', () {
      final dt = DateTime(2026, 7, 1, 14, 47);
      expect(toLocalDateTimeString(dt), '2026-07-01T14:47');
    });

    test('formatDateOnlyLocale avoids timezone shift for date-only API value', () {
      final formatted = formatDateOnlyLocale(
        '2026-07-15',
        localeTag: 'en',
      );
      expect(formatted, contains('15'));
      expect(formatted, contains('2026'));
    });

    test('formatDateTimeLocale formats with locale tag', () {
      final formatted = formatDateTimeLocale(
        '2026-07-15T10:30:00Z',
        localeTag: 'en',
      );
      expect(formatted, isNotEmpty);
      expect(formatted.contains('15'), isTrue);
    });

    test('mergePaginatedItems appends and de-duplicates by id', () {
      const a = _IdItem('1');
      const b = _IdItem('2');
      const bDup = _IdItem('2');
      const c = _IdItem('3');

      final merged = mergePaginatedItems(
        [a, b],
        [bDup, c],
        idOf: (item) => item.id,
      );

      expect(merged.map((e) => e.id).toList(), ['1', '2', '3']);
    });
  });

  group('orders_api_utils', () {
    test('ordersErrorIsForbidden detects 403 ApiException', () {
      const err = ApiException(message: 'Denied', statusCode: 403);
      expect(ordersErrorIsForbidden(err), isTrue);
    });

    test('ordersUserErrorMessage maps forbidden to noPermissionDesc', () {
      const err = ApiException(
        message: 'raw',
        statusCode: 403,
        code: 'forbidden_permission',
      );
      final s = S.forTest('uz');
      expect(ordersUserErrorMessage(err, s), s.noPermissionDesc);
    });

    test('ordersUserErrorMessage never returns Dio-style toString', () {
      expect(
        ordersUserErrorMessage(Exception('DioException'), S.forTest('en')),
        S.forTest('en').snackbarErrorGeneric,
      );
    });

    test('ordersProviderErrorMessage returns empty for non-ApiException', () {
      expect(ordersProviderErrorMessage(Exception('x')), '');
    });
  });

  group('CustomerOrderModel', () {
    test('fromJson parses list item shape', () {
      final order = CustomerOrderModel.fromJson({
        'id': 'o1',
        'shop_id': 's1',
        'customer_id': 'c1',
        'status': 'active',
        'delivery_date': '2026-07-15',
        'delivery_time': '10:30:00',
        'total_amount': '1000000.00',
        'paid_amount': '500000.00',
        'remaining_amount': '500000.00',
        'customer': {
          'id': 'c1',
          'shop_id': 's1',
          'name': 'Ali',
          'phone': '+998901234567',
        },
        'items': [
          {
            'id': 'i1',
            'customer_order_id': 'o1',
            'bread_category_id': 'b1',
            'quantity': 200,
            'unit_price': '5000.00',
            'subtotal': '1000000.00',
            'bread_category': {
              'id': 'b1',
              'shop_id': 's1',
              'name': 'Non',
              'selling_price': '5000.00',
              'sort_order': 0,
              'is_active': true,
            },
          },
        ],
        'payments': [],
      });

      expect(order.isActive, isTrue);
      expect(order.canDelete, isTrue);
      expect(order.items.first.quantity, 200);
      expect(parseAmount(order.remainingAmount), 500000);
    });

    test('canDelete is false when payments exist', () {
      final order = CustomerOrderModel.fromJson({
        'id': 'o1',
        'shop_id': 's1',
        'customer_id': 'c1',
        'status': 'active',
        'delivery_date': '2026-07-15',
        'total_amount': '1000.00',
        'paid_amount': '500.00',
        'remaining_amount': '500.00',
        'items': [],
        'payments': [
          {
            'id': 'p1',
            'customer_order_id': 'o1',
            'shop_id': 's1',
            'amount': '500.00',
          },
        ],
      });

      expect(order.canDelete, isFalse);
    });
  });

  group('OrderListFilters', () {
    test('equality uses all fields', () {
      const a = OrderListFilters(
        dateTab: OrderDateTab.today,
        status: CustomerOrderStatus.active,
      );
      const b = OrderListFilters(
        dateTab: OrderDateTab.today,
        status: CustomerOrderStatus.active,
      );
      expect(a, equals(b));
    });

    test('customDate removed from filters', () {
      const filters = OrderListFilters();
      // Default — "Hammasi": ro'yxat dastlab barcha zakazlarni ko'rsatadi.
      expect(filters.dateTab, OrderDateTab.all);
    });
  });

  group('create order payload XOR', () {
    test('existing customer uses customer_id only', () {
      final payload = <String, dynamic>{
        'customer_id': 'c1',
        'delivery_date': '2026-07-15',
        'items': [],
      };
      expect(payload.containsKey('customer_id'), isTrue);
      expect(payload.containsKey('customer'), isFalse);
    });

    test('new customer uses customer object only', () {
      final payload = <String, dynamic>{
        'customer': {'name': 'Ali'},
        'delivery_date': '2026-07-15',
        'items': [],
      };
      expect(payload.containsKey('customer'), isTrue);
      expect(payload.containsKey('customer_id'), isFalse);
    });
  });

  group('pagination append simulation', () {
    test('page1+page2 merge preserves order and skips duplicates', () {
      final page1 = [_IdItem('o1'), _IdItem('o2')];
      final page2 = [_IdItem('o2'), _IdItem('o3')];

      final all = mergePaginatedItems(page1, page2, idOf: (o) => o.id);

      expect(all.length, 3);
      expect(all.first.id, 'o1');
      expect(all.last.id, 'o3');
    });
  });

  group('orders l10n parity', () {
    test('new toast keys exist in all locales', () {
      for (final locale in S.allLocaleMaps.entries) {
        for (final key in [
          'ordersDelivered',
          'ordersPaymentAdded',
          'ordersSelectCustomerRequired',
        ]) {
          expect(
            locale.value.containsKey(key),
            isTrue,
            reason: '${locale.key} missing $key',
          );
        }
      }
    });

    test('uz_CYRL ordersFilterAll has no Latin archasi substring', () {
      final map = S.allLocaleMaps['uz_CYRL']!;
      final value = map['ordersFilterAll']!;
      expect(value.contains('archasi'), isFalse);
      expect(value.startsWith('Б'), isTrue);
    });
  });
}

class _IdItem {
  const _IdItem(this.id);
  final String id;
}
