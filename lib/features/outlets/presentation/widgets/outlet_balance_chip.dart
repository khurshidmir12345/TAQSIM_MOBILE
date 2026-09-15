import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/outlet_model.dart';

/// Qoldiq holati uchun rang va yorliq: qarz / oldindan / teng.
(Color, String) outletBalanceStyle(S s, OutletTotals t) {
  if (t.owes) return (AppColors.warning, s.outletBalanceOwes);
  if (t.prepaid) return (AppColors.info, s.outletBalancePrepaid);
  return (AppColors.success, s.outletBalanceSettled);
}

class OutletBalanceChip extends StatelessWidget {
  const OutletBalanceChip({
    super.key,
    required this.totals,
    required this.amountText,
  });

  final OutletTotals totals;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (color, label) = outletBalanceStyle(s, totals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amountText,
          maxLines: 1,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
