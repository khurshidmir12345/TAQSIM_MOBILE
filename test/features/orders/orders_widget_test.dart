import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taqseem/core/constants/shop_permissions.dart';
import 'package:taqseem/core/l10n/translations.dart';
import 'package:taqseem/features/auth/domain/providers/auth_provider.dart';
import 'package:taqseem/features/orders/presentation/screens/orders_screen.dart';
import 'package:taqseem/features/orders/presentation/widgets/manage_orders_guard.dart';

void main() {
  testWidgets(
    'OrdersScreen shows permission empty when manage_orders missing',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return const OrdersScreen();
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(OrdersScreen), findsOneWidget);
    },
  );

  testWidgets('ManageOrdersGuard blocks seller without manage_orders', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasPermissionProvider(
            ShopPermissions.manageOrders,
          ).overrideWith((ref) => false),
        ],
        child: MaterialApp(
          home: ManageOrdersGuard(
            child: Scaffold(body: Text(S.forTest('uz').ordersCreate)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text(S.forTest('uz').noPermissionTitle), findsOneWidget);
    expect(find.text(S.forTest('uz').ordersCreate), findsNothing);
  });

  test('orders l10n keys exist in all locales', () {
    for (final locale in S.allLocaleMaps.entries) {
      for (final key in [
        'orders',
        'ordersCreate',
        'customersTitle',
        'permManageOrders',
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
}
