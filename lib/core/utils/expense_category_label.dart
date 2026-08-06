import '../l10n/api_locale_holder.dart';

/// Tizim (built-in) xarajat kategoriyalari yorliqlari.
/// Manba — backend `lang/<locale>/expense.php`; kalitlar
/// `config/expense_categories.php` dagi `built_in` kodlari.
///
/// Hisobot API'si `expenses.by_category` ni xom kalit bilan qaytaradi
/// (`ish_haqi`, yoki foydalanuvchi kategoriyasi uchun UUID), shuning uchun
/// ekranga chiqarishdan oldin shu yerdan tarjima olinadi.
const Map<String, Map<String, String>> kExpenseCategoryLabels = {
  'uz': {
    'otyin': "O'tin",
    'gaz': "Gaz",
    'elektr': "Elektr",
    'ijara': "Ijara",
    'transport': "Transport",
    'ish_haqi': "Ish haqi",
    'kommunal': "Kommunal",
    'maosh': "Maosh",
    'boshqa': "Boshqa",
  },
  'uz_CYRL': {
    'otyin': "Ўтин",
    'gaz': "Газ",
    'elektr': "Электр",
    'ijara': "Ижара",
    'transport': "Транспорт",
    'ish_haqi': "Иш ҳақи",
    'kommunal': "Коммунал",
    'maosh': "Маош",
    'boshqa': "Бошқа",
  },
  'ru': {
    'otyin': "Дрова",
    'gaz': "Газ",
    'elektr': "Электричество",
    'ijara': "Аренда",
    'transport': "Транспорт",
    'ish_haqi': "Зарплата",
    'kommunal': "Коммунальные",
    'maosh': "Оплата труда",
    'boshqa': "Прочее",
  },
  'kk': {
    'otyin': "Отын",
    'gaz': "Газ",
    'elektr': "Электр",
    'ijara': "Жалға алу",
    'transport': "Көлік",
    'ish_haqi': "Жалақы",
    'kommunal': "Коммуналдық",
    'maosh': "Жалақы",
    'boshqa': "Басқа",
  },
  'ky': {
    'otyin': "Отун",
    'gaz': "Газ",
    'elektr': "Электр",
    'ijara': "Ижара",
    'transport': "Транспорт",
    'ish_haqi': "Эмгек акы",
    'kommunal': "Коммуналдык",
    'maosh': "Эмгек акы",
    'boshqa': "Башка",
  },
  'tr': {
    'otyin': "Odun",
    'gaz': "Gaz",
    'elektr': "Elektrik",
    'ijara': "Kira",
    'transport': "Ulaşım",
    'ish_haqi': "Ücret",
    'kommunal': "Faturalar",
    'maosh': "Maaş",
    'boshqa': "Diğer",
  },
  'en': {
    'otyin': "Firewood",
    'gaz': "Gas",
    'elektr': "Electricity",
    'ijara': "Rent",
    'transport': "Transport",
    'ish_haqi': "Labor",
    'kommunal': "Utilities",
    'maosh': "Salary",
    'boshqa': "Other",
  },
};

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// `by_category` kalitini foydalanuvchiga ko‘rsatiladigan nomga aylantiradi.
///
/// [customNames] — API'dan olingan `id → nom` jufti (foydalanuvchi yaratgan
/// kategoriyalar UUID bilan keladi). Yuklanmagan bo‘lsa tizim kategoriyalari
/// baribir to‘g‘ri ko‘rinadi, UUID esa hech qachon ekranga chiqmaydi.
String expenseCategoryLabel(
  String key, {
  String? locale,
  Map<String, String>? customNames,
}) {
  final custom = customNames?[key];
  if (custom != null && custom.trim().isNotEmpty) return custom;

  final byLocale = kExpenseCategoryLabels[locale ?? ApiLocaleHolder.code] ??
      kExpenseCategoryLabels['uz']!;

  final builtIn = byLocale[key];
  if (builtIn != null) return builtIn;

  // Nomi hali yuklanmagan foydalanuvchi kategoriyasi — UUID ko‘rsatilmaydi.
  if (_uuidPattern.hasMatch(key)) return byLocale['boshqa'] ?? key;

  return key;
}
