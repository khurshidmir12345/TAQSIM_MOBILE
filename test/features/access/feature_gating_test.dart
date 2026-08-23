import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/constants/shop_features.dart';
import 'package:taqseem/core/widgets/feature_guard.dart';
import 'package:taqseem/features/auth/domain/models/shop_model.dart';
import 'package:taqseem/features/auth/domain/providers/auth_provider.dart';
import 'package:taqseem/features/auth/domain/providers/shop_provider.dart';

/// Muddat tugagach bo'lim neytral xabar ko'rsatishi kerak.
///
/// Xabarda narx, to'lov yoki obuna haqida bir og'iz so'z bo'lmasligi shart —
/// bu do'kon qoidalari talabi, shuning uchun alohida sinaladi.
void main() {
  ShopModel shop({List<String> features = const []}) {
    return ShopModel(
      id: 'shop-1',
      name: 'Test',
      slug: 'test',
      userType: 'owner',
      permissions: const ['manage_orders', 'view_reports'],
      features: features,
    );
  }

  Future<void> pump(WidgetTester tester, ShopModel selected) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopProvider.overrideWith(
            () => _StubShopNotifier(ShopState(shops: [selected], selected: selected)),
          ),
        ],
        child: const MaterialApp(
          home: FeatureGuard(
            feature: ShopFeatures.reports,
            child: Scaffold(body: Text('ichki kontent')),
          ),
        ),
      ),
    );
  }

  testWidgets('bo\'lim ochiq bo\'lsa kontent ko\'rinadi', (tester) async {
    await pump(tester, shop(features: [ShopFeatures.reports]));
    await tester.pumpAndSettle();

    expect(find.text('ichki kontent'), findsOneWidget);
  });

  testWidgets('bo\'lim yopiq bo\'lsa kontent ko\'rinmaydi', (tester) async {
    await pump(tester, shop());
    await tester.pumpAndSettle();

    expect(find.text('ichki kontent'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('yopiq holat xabarida narx yoki to\'lov haqida gap yo\'q',
      (tester) async {
    await pump(tester, shop());
    await tester.pumpAndSettle();

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? '').toLowerCase())
        .join(' ');

    expect(texts, isNotEmpty);
    for (final banned in [
      'narx', 'to\'lov', 'tolov', 'obuna', 'tarif', 'premium', 'pullik',
      'sotib', 'price', 'pay', 'subscri', 'upgrade', 'plan', 'trial',
    ]) {
      expect(texts.contains(banned), isFalse,
          reason: 'Yopiq holat xabarida "$banned" so\'zi bo\'lmasligi kerak');
    }
  });

  testWidgets('boshqa bo\'lim ochiq bo\'lsa ham bu bo\'lim yopiq qoladi',
      (tester) async {
    await pump(tester, shop(features: [ShopFeatures.orders]));
    await tester.pumpAndSettle();

    expect(find.text('ichki kontent'), findsNothing);
  });

  group('ShopModel.features', () {
    test('javobdagi ro\'yxat o\'qiladi', () {
      final parsed = ShopModel.fromJson(const {
        'id': 'a',
        'name': 'Shop',
        'slug': 'shop',
        'permissions': ['manage_orders'],
        'features': ['reports', 'orders'],
      });

      expect(parsed.features, ['reports', 'orders']);
    });

    test('features yo\'q bo\'lsa bo\'sh ro\'yxat — eski server bilan ham ishlaydi',
        () {
      final parsed = ShopModel.fromJson(const {
        'id': 'a',
        'name': 'Shop',
        'slug': 'shop',
      });

      expect(parsed.features, isEmpty);
      expect(parsed.permissions, isEmpty);
    });
  });
}

class _StubShopNotifier extends ShopNotifier {
  _StubShopNotifier(this._initial);

  final ShopState _initial;

  @override
  ShopState build() => _initial;
}
