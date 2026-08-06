import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taqseem/core/l10n/translations.dart';
import 'package:taqseem/features/auth/domain/models/shop_model.dart';
import 'package:taqseem/features/auth/domain/providers/shop_provider.dart';
import 'package:taqseem/features/orders/data/orders_repository.dart';
import 'package:taqseem/features/orders/domain/models/customer_order_model.dart';
import 'package:taqseem/features/orders/domain/providers/customer_provider.dart';
import 'package:taqseem/features/orders/presentation/widgets/order_form.dart';
import 'package:taqseem/features/setup/domain/providers/setup_provider.dart';

const _testShop = ShopModel(id: 's1', name: 'Test shop', slug: 'test-shop');

Dio _trackingDio(void Function(RequestOptions options) onRequest) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'data': [
                {'id': 'c1', 'shop_id': 's1', 'name': 'Ali'},
              ],
              'meta': {
                'current_page': 1,
                'last_page': 1,
                'per_page': 20,
                'total': 1,
              },
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return dio;
}

bool _isPaginatedCustomerRequest(RequestOptions options) {
  final paginate = options.queryParameters['paginate'];
  return paginate == true || paginate == 'true';
}

Future<void> _waitForAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

class _TestShopNotifier extends ShopNotifier {
  @override
  ShopState build() => const ShopState(selected: _testShop);
}

class _IdleBreadCategoryNotifier extends BreadCategoryNotifier {
  @override
  BreadCategoryListState build() => const BreadCategoryListState();

  @override
  Future<void> load() async {}
}

ProviderContainer _pickerContainer(Dio dio) {
  return ProviderContainer(
    overrides: [
      shopProvider.overrideWith(_TestShopNotifier.new),
      customerRepositoryProvider.overrideWithValue(CustomerRepository(dio)),
    ],
  );
}

Widget _orderFormHarness({
  required Widget child,
  required Dio dio,
}) {
  return ProviderScope(
    overrides: [
      shopProvider.overrideWith(_TestShopNotifier.new),
      customerRepositoryProvider.overrideWithValue(CustomerRepository(dio)),
      breadCategoryProvider.overrideWith(_IdleBreadCategoryNotifier.new),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

CustomerOrderModel _sampleEditOrder() {
  return CustomerOrderModel.fromJson({
    'id': 'o1',
    'shop_id': 's1',
    'customer_id': 'c1',
    'status': 'active',
    'delivery_date': '2026-07-15',
    'total_amount': '1000.00',
    'paid_amount': '0.00',
    'remaining_amount': '1000.00',
    'customer': {
      'id': 'c1',
      'shop_id': 's1',
      'name': 'Ali',
    },
    'items': [
      {
        'id': 'i1',
        'customer_order_id': 'o1',
        'bread_category_id': 'b1',
        'quantity': 1,
        'unit_price': '1000.00',
        'subtotal': '1000.00',
      },
    ],
    'payments': [],
  });
}

void main() {
  group('CustomerPickerNotifier', () {
    test('build does not fetch until ensureLoaded is called', () async {
      var paginatedCalls = 0;
      final container = _pickerContainer(
        _trackingDio((options) {
          if (_isPaginatedCustomerRequest(options)) {
            paginatedCalls++;
          }
        }),
      );
      addTearDown(container.dispose);

      expect(container.read(customerPickerProvider).isLoading, isFalse);
      expect(container.read(customerPickerProvider).items, isEmpty);
      expect(paginatedCalls, 0);

      await container.read(customerPickerProvider.notifier).ensureLoaded();
      await Future<void>.delayed(Duration.zero);

      expect(paginatedCalls, 1);
      expect(container.read(customerPickerProvider).items, hasLength(1));
    });

    test('ensureLoaded is idempotent while data is present', () async {
      var paginatedCalls = 0;
      final container = _pickerContainer(
        _trackingDio((options) {
          if (_isPaginatedCustomerRequest(options)) {
            paginatedCalls++;
          }
        }),
      );
      addTearDown(container.dispose);

      final notifier = container.read(customerPickerProvider.notifier);
      await notifier.ensureLoaded();
      await Future<void>.delayed(Duration.zero);
      await notifier.ensureLoaded();
      await Future<void>.delayed(Duration.zero);

      expect(paginatedCalls, 1);
    });
  });

  group('OrderForm customer picker loading', () {
    testWidgets('plain create auto-loads existing-customer picker', (
      tester,
    ) async {
      var paginatedCalls = 0;

      await tester.pumpWidget(
        _orderFormHarness(
          dio: _trackingDio((options) {
            if (_isPaginatedCustomerRequest(options)) {
              paginatedCalls++;
            }
          }),
          child: OrderForm(onSubmit: (_) async {}),
        ),
      );

      await _waitForAsync(tester);

      expect(paginatedCalls, 1);
      expect(find.byType(OrderForm), findsOneWidget);
    });

    testWidgets('edit mode does not load customer picker', (tester) async {
      var paginatedCalls = 0;

      await tester.pumpWidget(
        _orderFormHarness(
          dio: _trackingDio((options) {
            if (_isPaginatedCustomerRequest(options)) {
              paginatedCalls++;
            }
          }),
          child: OrderForm(
            order: _sampleEditOrder(),
            onSubmit: (_) async {},
          ),
        ),
      );

      await _waitForAsync(tester);

      expect(paginatedCalls, 0);
    });

    testWidgets('switching to inline-new customer skips picker fetch', (
      tester,
    ) async {
      var paginatedCalls = 0;

      await tester.pumpWidget(
        _orderFormHarness(
          dio: _trackingDio((options) {
            if (_isPaginatedCustomerRequest(options)) {
              paginatedCalls++;
            }
          }),
          child: OrderForm(onSubmit: (_) async {}),
        ),
      );

      await _waitForAsync(tester);
      expect(paginatedCalls, 1);

      await tester.tap(find.text(S.forTest('uz').ordersNewCustomer));
      await tester.pump();

      expect(paginatedCalls, 1);
    });
  });
}
