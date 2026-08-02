import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/core/l10n/translations.dart';

void main() {
  const customerKeys = [
    'customersTitle',
    'customersNewTitle',
    'customersEditTitle',
    'customersDetailTitle',
    'customersEmpty',
    'customersEmptyDesc',
    'customersCreated',
    'customersUpdated',
    'customersDeleted',
    'customersDeleteTitle',
    'customersDeleteConfirm',
    'customersNoteLabel',
    'customersNameLabel',
    'customersOrdersHistory',
    'customersSearchHint',
    'customersCreateOrder',
    'customersNotFound',
    'permManageOrders',
    'permManageOrdersDesc',
    'noPermissionTitle',
    'noPermissionDesc',
  ];

  bool hasLatin(String value) => RegExp(r'[A-Za-z]').hasMatch(value);

  group('customers and permission l10n quality', () {
    for (final locale in ['uz_CYRL', 'kk', 'ky']) {
      test('$locale customer strings avoid Latin mixing', () {
        final map = S.allLocaleMaps[locale]!;
        for (final key in customerKeys) {
          final value = map[key]!;
          expect(value.trim().isNotEmpty, isTrue, reason: key);
          expect(
            hasLatin(value),
            isFalse,
            reason: '$locale.$key still contains Latin: $value',
          );
        }
      });
    }

    test('customersDeleteConfirm keeps placeholder-free uz copy', () {
      final uz = S.allLocaleMaps['uz']!;
      expect(uz['customersDeleteConfirm'], contains('Davom etasizmi'));
      expect(uz['customersDeleteConfirm'], isNot(contains('{')));
    });

    test('customersDeleteConfirm question parity across Cyrillic locales', () {
      final uzCyrl = S.allLocaleMaps['uz_CYRL']!;
      final kk = S.allLocaleMaps['kk']!;
      final ky = S.allLocaleMaps['ky']!;

      expect(uzCyrl['customersDeleteConfirm'], endsWith('?'));
      expect(kk['customersDeleteConfirm'], endsWith('?'));
      expect(ky['customersDeleteConfirm'], endsWith('?'));

      expect(uzCyrl['customersDeleteConfirm'], contains('.'));
      expect(kk['customersDeleteConfirm'], contains('.'));
      expect(ky['customersDeleteConfirm'], contains('.'));
    });

    test('representative Cyrillic/Kazakh/Kyrgyz customer strings', () {
      expect(S.allLocaleMaps['uz_CYRL']!['customersTitle'], 'Мижозлар');
      expect(S.allLocaleMaps['kk']!['customersTitle'], 'Клиенттер');
      expect(S.allLocaleMaps['ky']!['customersTitle'], 'Кардарлар');

      expect(S.allLocaleMaps['uz_CYRL']!['permManageOrders'], 'Заказлар');
      expect(S.allLocaleMaps['kk']!['permManageOrders'], 'Тапсырыстар');
      expect(S.allLocaleMaps['ky']!['permManageOrders'], 'Заказдар');
    });

    test('ky customersEmptyDesc is customer-specific full Cyrillic copy', () {
      const expected = 'Биринчи кардараңызды кошу';
      final ky = S.allLocaleMaps['ky']!;

      expect(ky['customersEmptyDesc'], expected);
      expect(ky['customersEmptyDesc'], contains('кардар'));
      expect(ky['customersEmptyDesc'], isNot(contains('кызматкер')));
      expect(ky['customersEmptyDesc'], isNot(contains('уруксат')));
      expect(hasLatin(ky['customersEmptyDesc']!), isFalse);
    });

    test('all locales have customer/permission parity', () {
      final reference = S.referenceKeys;
      for (final entry in S.allLocaleMaps.entries) {
        for (final key in customerKeys) {
          expect(
            entry.value.containsKey(key),
            isTrue,
            reason: '${entry.key} missing $key',
          );
          expect(
            reference.contains(key),
            isTrue,
            reason: 'reference missing $key',
          );
        }
      }
    });
  });
}
