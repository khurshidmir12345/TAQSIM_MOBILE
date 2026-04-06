import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/l10n/translations.dart';
import '../../../domain/models/bread_return_model.dart';
import 'return_detail_sheet.dart';

class ReturnHistoryCard extends StatelessWidget {
  const ReturnHistoryCard({
    super.key,
    required this.r,
    required this.fmtMoney,
  });

  final BreadReturnModel r;
  final String Function(double) fmtMoney;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final name = r.breadCategory?.name ?? s.unknown;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showReturnDetailSheet(context, r),
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 2),
            border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.undo_rounded,
                    color: AppColors.error.withValues(alpha: 0.9),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.quantity} ${s.pcs} · ${fmtMoney(r.pricePerUnit)} ${s.currency}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${fmtMoney(r.totalAmount)} ${s.currency}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
