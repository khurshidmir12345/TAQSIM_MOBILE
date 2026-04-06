import 'package:flutter/material.dart';

IconData expenseCategoryIconData(String icon) {
  switch (icon) {
    case 'fire':
      return Icons.local_fire_department_rounded;
    case 'gas_station':
      return Icons.local_gas_station_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'apartment':
      return Icons.apartment_rounded;
    case 'directions_bus':
      return Icons.directions_bus_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'water':
      return Icons.water_drop_rounded;
    case 'badge':
      return Icons.badge_rounded;
    case 'more_horiz':
      return Icons.more_horiz_rounded;
    case 'tune':
      return Icons.tune_rounded;
    case 'category':
    default:
      return Icons.category_rounded;
  }
}
