import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/widgets.dart';

/// Tarif limiti to'lganda ko'rsatiladigan upgrade bottom sheet.
/// [resource] — 'products' | 'shops' | 'employees'.
Future<void> showPlanLimitSheet(BuildContext context, String resource) {
  final s = S.of(context);
  final message = switch (resource) {
    'shops' => s.limitReachedShops,
    'employees' => s.limitReachedEmployees,
    _ => s.limitReachedProducts,
  };

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.gold, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              s.limitReachedTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: s.viewPlans,
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                ctx.push('/subscription');
              },
            ),
          ],
        ),
      );
    },
  );
}
