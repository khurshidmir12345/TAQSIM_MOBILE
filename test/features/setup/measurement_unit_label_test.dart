import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/l10n/api_locale_holder.dart';
import 'package:taqseem/features/auth/domain/models/measurement_unit_model.dart';

/// API `MeasurementUnitResource` qaytaradigan shakl.
MeasurementUnitModel unit(
  String code, {
  Map<String, String> names = const {},
  String? name,
  String type = 'batch',
}) {
  return MeasurementUnitModel.fromJson({
    'id': 'id-$code',
    'type': type,
    'code': code,
    'icon': '📦',
    if (name != null) 'name': name,
    'names': names,
    'examples': const <String, dynamic>{},
    'sort_order': 1,
  });
}

void main() {
  setUp(() => ApiLocaleHolder.setCode('uz'));

  group('batchShortLabel — partiya izohi olib tashlanadi', () {
    test('dona_batch xom kod emas, "Dona" ko‘rsatadi', () {
      final u = unit('dona_batch', names: {
        'uz': 'Dona (partiya)',
        'uz_CYRL': 'Дона (партия)',
        'ru': 'Шт. (партия)',
      });

      expect(u.batchShortLabel('uz'), 'Dona');
      expect(u.batchShortLabel('uz_CYRL'), 'Дона');
      expect(u.batchShortLabel('ru'), 'Шт.');
    });

    test('kg_batch eski qattiq kodlangan "KG" bilan bir xil qoladi', () {
      final u = unit('kg_batch', names: {'uz': 'KG (partiya)'});
      expect(u.batchShortLabel('uz'), 'KG');
    });

    test('l_batch va m_batch ham tozalanadi', () {
      expect(
        unit('l_batch', names: {'uz': 'Litr (partiya)'}).batchShortLabel('uz'),
        'Litr',
      );
      expect(
        unit('m_batch', names: {'uz': 'Metr (partiya)'}).batchShortLabel('uz'),
        'Metr',
      );
    });

    test('qavssiz nomlar o‘zgarmaydi', () {
      expect(unit('qop', names: {'uz': 'Qop'}).batchShortLabel('uz'), 'Qop');
      expect(
        unit('qozon', names: {'uz': 'Qozon'}).batchShortLabel('uz'),
        'Qozon',
      );
      expect(
        unit('m3', names: {'uz': 'Kubometr'}).batchShortLabel('uz'),
        'Kubometr',
      );
    });

    test('noma’lum locale uz ga qaytadi, xom kodga emas', () {
      final u = unit('dona_batch', names: {'uz': 'Dona (partiya)'});
      expect(u.batchShortLabel('de'), 'Dona');
    });
  });

  group('so‘nggi himoya — hech qachon pastki chiziq chiqmaydi', () {
    test('API nom yubormasa ham kod chiroyli ko‘rinadi', () {
      final u = unit('dona_batch');
      expect(u.batchShortLabel('uz'), 'Dona');
      expect(u.batchShortLabel('uz'), isNot(contains('_')));
    });

    test('qisqa kodlar bosh harf bilan', () {
      expect(unit('l_batch').batchShortLabel('uz'), 'L');
      expect(unit('kg_batch').batchShortLabel('uz'), 'KG');
    });
  });

  group('batchDisplayLabel joriy API tilini ishlatadi', () {
    test('locale o‘zgarsa yorliq ham o‘zgaradi', () {
      final u = unit('dona_batch', names: {
        'uz': 'Dona (partiya)',
        'ru': 'Шт. (партия)',
      });

      ApiLocaleHolder.setCode('uz');
      expect(u.batchDisplayLabel, 'Dona');

      ApiLocaleHolder.setCode('ru');
      expect(u.batchDisplayLabel, 'Шт.');
    });
  });
}
