class CountryPhone {
  final String name;
  final String flag;
  final String dialCode;
  final String isoCode;
  final String phoneMask; // X = digit
  final int maxDigits;

  const CountryPhone({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.isoCode,
    required this.phoneMask,
    required this.maxDigits,
  });

  String get fullLabel => '$flag  $dialCode';
}

abstract final class AppCountries {
  static const uz = CountryPhone(
    name: "O'zbekiston",
    flag: '🇺🇿',
    dialCode: '+998',
    isoCode: 'UZ',
    phoneMask: 'XX XXX XX XX',
    maxDigits: 9,
  );

  static const ru = CountryPhone(
    name: 'Россия',
    flag: '🇷🇺',
    dialCode: '+7',
    isoCode: 'RU',
    phoneMask: 'XXX XXX XX XX',
    maxDigits: 10,
  );

  static const kz = CountryPhone(
    name: 'Қазақстан',
    flag: '🇰🇿',
    dialCode: '+7',
    isoCode: 'KZ',
    phoneMask: 'XXX XXX XX XX',
    maxDigits: 10,
  );

  static const kg = CountryPhone(
    name: 'Кыргызстан',
    flag: '🇰🇬',
    dialCode: '+996',
    isoCode: 'KG',
    phoneMask: 'XXX XXX XXX',
    maxDigits: 9,
  );

  static const tr = CountryPhone(
    name: 'Türkiye',
    flag: '🇹🇷',
    dialCode: '+90',
    isoCode: 'TR',
    phoneMask: 'XXX XXX XX XX',
    maxDigits: 10,
  );

  static const List<CountryPhone> all = [uz, ru, kz, kg, tr];
}
