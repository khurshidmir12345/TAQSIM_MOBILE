import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/features/orders/data/orders_repository.dart';
import 'package:taqseem/features/orders/domain/utils/money_utils.dart';

Dio _mockDio(
  Object? Function(RequestOptions options) responder, {
  int statusCode = 200,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: responder(options),
            statusCode: statusCode,
          ),
        );
      },
    ),
  );
  return dio;
}

Map<String, dynamic> _orderJson({required String id, required String status}) {
  return {
    'id': id,
    'shop_id': 's1',
    'customer_id': 'c1',
    'status': status,
    'delivery_date': '2026-07-15',
    'total_amount': '1000.00',
    'paid_amount': '0.00',
    'remaining_amount': '1000.00',
    'items': [],
    'payments': [],
  };
}

void main() {
  group('CustomerRepository', () {
    test('fetchCustomersPaginated parses paginated wrapper', () async {
      final repo = CustomerRepository(
        _mockDio(
          (_) => {
            'data': [
              {
                'id': 'c1',
                'shop_id': 's1',
                'name': 'Ali',
              },
            ],
            'meta': {
              'current_page': 1,
              'last_page': 2,
              'per_page': 20,
              'total': 25,
            },
          },
        ),
      );

      final page = await repo.fetchCustomersPaginated('s1', page: 1);
      expect(page.items.single.name, 'Ali');
      expect(page.currentPage, 1);
      expect(page.lastPage, 2);
      expect(page.total, 25);
    });

    test('searchCustomers parses data.customers wrapper', () async {
      final repo = CustomerRepository(
        _mockDio(
          (_) => {
            'data': {
              'customers': [
                {
                  'id': 'c2',
                  'shop_id': 's1',
                  'name': 'Vali',
                },
              ],
            },
          },
        ),
      );

      final customers = await repo.searchCustomers('s1', search: 'va');
      expect(customers.single.name, 'Vali');
    });

    test('getCustomer parses single wrapper', () async {
      final repo = CustomerRepository(
        _mockDio(
          (_) => {
            'data': {
              'customer': {
                'id': 'c1',
                'shop_id': 's1',
                'name': 'Ali',
              },
            },
          },
        ),
      );

      final customer = await repo.getCustomer('s1', 'c1');
      expect(customer.name, 'Ali');
    });

    test('deleteCustomer accepts 204 empty response', () async {
      var deletePath = '';
      final repo = CustomerRepository(
        _mockDio((options) {
          deletePath = options.path;
          return null;
        }, statusCode: 204),
      );

      await expectLater(repo.deleteCustomer('s1', 'c1'), completes);
      expect(deletePath, '/v1/shops/s1/customers/c1');
    });
  });

  group('OrderRepository', () {
    test('fetchOrdersPaginated parses paginated wrapper', () async {
      final repo = OrderRepository(
        _mockDio(
          (_) => {
            'data': [
              _orderJson(id: 'o1', status: 'active'),
            ],
            'meta': {
              'current_page': 1,
              'last_page': 3,
              'per_page': 20,
              'total': 42,
            },
          },
        ),
      );

      final page = await repo.fetchOrdersPaginated('s1', page: 1);
      expect(page.items.single.id, 'o1');
      expect(page.currentPage, 1);
      expect(page.lastPage, 3);
      expect(page.total, 42);
    });

    test('createOrder sends XOR customer_id payload', () async {
      Map<String, dynamic>? captured;
      final repo = OrderRepository(
        _mockDio((options) {
          captured = options.data as Map<String, dynamic>?;
          return {
            'data': {
              'customer_order': _orderJson(id: 'o1', status: 'active'),
            },
          };
        }),
      );

      await repo.createOrder('s1', {
        'customer_id': 'c1',
        'delivery_date': '2026-07-15',
        'items': [],
      });

      expect(captured?['customer_id'], 'c1');
      expect(captured?.containsKey('customer'), isFalse);
    });

    test('addPayment sends paid_at datetime payload', () async {
      Map<String, dynamic>? captured;
      final repo = OrderRepository(
        _mockDio((options) {
          captured = options.data as Map<String, dynamic>?;
          return {
            'data': {
              'customer_order': _orderJson(id: 'o1', status: 'active'),
            },
          };
        }),
      );

      await repo.addPayment(
        's1',
        'o1',
        amount: 500,
        paidAt: toLocalDateTimeString(DateTime(2026, 3, 15, 14, 30)),
      );

      expect(captured?['paid_at'], '2026-03-15T14:30');
    });

    test('deliverOrder posts action payload', () async {
      Map<String, dynamic>? captured;
      final repo = OrderRepository(
        _mockDio((options) {
          captured = options.data as Map<String, dynamic>?;
          return {
            'data': {
              'customer_order': _orderJson(id: 'o1', status: 'delivered'),
            },
          };
        }),
      );

      await repo.deliverOrder('s1', 'o1', paymentAmount: 250);

      expect(captured?['payment_amount'], 250);
    });

    test('deleteOrder accepts 204 empty response', () async {
      var deletePath = '';
      final repo = OrderRepository(
        _mockDio((options) {
          deletePath = options.path;
          return null;
        }, statusCode: 204),
      );

      await expectLater(repo.deleteOrder('s1', 'o1'), completes);
      expect(deletePath, '/v1/shops/s1/customer-orders/o1');
    });
  });
}
