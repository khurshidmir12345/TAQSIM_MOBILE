import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/outlet_model.dart';

/// Qoldiq holati: qarz — qizil, «−» bilan; oldindan to'langan — yashil, «+»;
/// teng — kulrang.
(Color, String, String) outletBalanceStyle(
  BuildContext context,
  S s,
  OutletTotals t,
) {
  final cs = Theme.of(context).colorScheme;
  if (t.owes) return (AppColors.error, s.outletBalanceOwes, '−');
  if (t.prepaid) return (AppColors.success, s.outletBalancePrepaid, '+');
  return (cs.onSurface.withValues(alpha: 0.45), s.outletBalanceSettled, '');
}

class OutletBalanceChip extends StatelessWidget {
  const OutletBalanceChip({
    super.key,
    required this.totals,
    required this.amountText,
  });

  final OutletTotals totals;

  /// Ishorasiz, valyutasiz summa — ishora shu yerda qo'yiladi.
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (color, label, sign) = outletBalanceStyle(context, s, totals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$sign$amountText',
          maxLines: 1,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
