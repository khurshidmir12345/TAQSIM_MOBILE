/// Hisob muddati bo'yicha ochiladigan bo'limlar
/// (backend `config/access.php` dagi `paid_features` bilan mos).
///
/// Ro'yxatda yo'q hamma narsa — bosh sahifa, mahsulot/xomashyo/retsept,
/// ishlab chiqarish, qaytarish, kassa — doim ochiq va tekshirilmaydi.
class ShopFeatures {
  ShopFeatures._();

  /// Statistika sahifasi: grafik, umumiy summalar, haqiqiy tannarx.
  static const String reports = 'reports';

  /// Buyurtmalar va mijozlar.
  static const String orders = 'orders';

  /// Xodim qo'shish va ruxsatlarini boshqarish.
  static const String employees = 'employees';

  /// Ikkinchi va undan keyingi biznes.
  static const String multiShop = 'multi_shop';
}
