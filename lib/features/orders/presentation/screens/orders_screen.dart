import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';

/// Zakazlar bo'limi — hozircha "tez orada" holatida.
///
/// To'liq ro'yxat implementatsiyasi `orders_list_view.dart` da saqlangan
/// (kelajakda ishga tushganda qayta ulanadi). Backend `/v1/orders` endpointi
/// ham mavjud bo'lib qoladi.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(s.orders,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad + 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.primary.withValues(alpha: 0.55),
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                s.ordersComingSoon,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                s.ordersComingSoonDesc,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
