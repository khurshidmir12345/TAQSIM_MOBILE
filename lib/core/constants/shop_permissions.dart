/// Do'kon ichidagi modul ruxsatlari (backend `ShopPermission` enum bilan mos).
///
/// Owner doim barcha ruxsatlarga ega; seller uchun backend pivotdan keladi.
class ShopPermissions {
  ShopPermissions._();

  static const String viewReports = 'view_reports';
  static const String manageProducts = 'manage_products';
  static const String manageRecipes = 'manage_recipes';
  static const String manageProduction = 'manage_production';
  static const String manageExpenses = 'manage_expenses';
  static const String manageSales = 'manage_sales';
  static const String manageOrders = 'manage_orders';

  static const List<String> all = [
    viewReports,
    manageProducts,
    manageRecipes,
    manageProduction,
    manageExpenses,
    manageSales,
    manageOrders,
  ];
}
