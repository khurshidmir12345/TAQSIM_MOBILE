import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/l10n/translations.dart';

/// Ilova ichida sotuv haqida hech narsa bo'lmasligi kerak.
///
/// App Store 3.1.3(f) bo'yicha bepul hamroh ilova IAP'siz ishlashi mumkin,
/// lekin **ilova ichida xarid ham, tashqi xaridga chaqiruv ham** bo'lmasligi
/// shart. Narx, tarif va to'lov haqidagi gaplar faqat ilovadan tashqarida —
/// Telegram bot, sayt va qo'ng'iroqda.
///
/// Ilgari ilovada butun bir hamyon/tarif matnlari to'plami turgan edi
/// (`paywallTitle`, `topUpNow`, `'Purchase {plan} plan for {price}'` ...) —
/// hech qayerda ishlatilmasa ham binary ichida. Bu test ularning qaytib
/// kelishini to'xtatadi.
void main() {
  /// Ilovada umuman uchramasligi kerak bo'lgan so'zlar.
  ///
  /// Ro'yxat ataylab tor. Chetda qolganlar va sabablari:
  ///  * "narx" / "price" — mahsulotning sotuv narxi uchun kerak;
  ///  * "tarif" — turkchada retsept degani ("Tarifler"), billing emas;
  ///  * "обнови" — ruschada "yangilash" (parol va ilova versiyasi).
  const banned = <String>[
    'obuna', 'подписк', 'subscription', 'subscribe',
    'тариф',
    'premium', 'премиум',
    'paywall',
    'hamyon', 'кошелёк', 'wallet',
    'to‘ldirish', "to'ldirish", 'пополн', 'top up', 'top-up',
    'sotib oling', 'sotib olish', 'купить', 'purchase', 'buy now',
    'upgrade',
    'sinov muddati', 'пробный период', 'free trial',
  ];

  test('tarjimalarda sotuv/to\'lov haqida matn yo\'q', () {
    final offenders = <String>[];

    for (final locale in S.allLocaleMaps.entries) {
      for (final entry in locale.value.entries) {
        final value = entry.value.toLowerCase();
        for (final word in banned) {
          if (value.contains(word)) {
            offenders.add('${locale.key}/${entry.key}: "$word" → ${entry.value}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Ilova ichida sotuv haqida matn bo\'lmasligi kerak. '
          'Bunday matnlar faqat serverda (Telegram boti) yashaydi.\n'
          '${offenders.join('\n')}',
    );
  });

  test('kalit nomlarida ham billing izlari qolmagan', () {
    const bannedKeys = <String>[
      'paywall', 'subscription', 'wallet', 'topup', 'premium',
      'plan', 'billing', 'purchase', 'trial', 'receipt',
    ];

    final offenders = S.referenceKeys
        .where((key) => bannedKeys.any((b) => key.toLowerCase().contains(b)))
        .toList();

    expect(offenders, isEmpty, reason: 'Qolgan kalitlar: $offenders');
  });
}
