import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/providers/subscription_provider.dart';

/// Dashboard tepasida ko'rinadigan obuna holati banneri.
/// Trial yoki grace davrida ko'rinadi, aks holda bo'sh.
class SubscriptionBanner extends ConsumerWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return statusAsync.maybeWhen(
      data: (st) {
        final sub = st.subscription;
        if (sub == null) return const SizedBox.shrink();

        final isTrial = sub.status == 'trialing';
        final isGrace = sub.status == 'grace';
        if (!isTrial && !isGrace) return const SizedBox.shrink();

        final Color color = isGrace ? AppColors.error : AppColors.gold;
        final IconData icon =
            isGrace ? Icons.warning_amber_rounded : Icons.timer_outlined;
        final String title = isGrace
            ? s.graceWarning.replaceAll('{n}', '${sub.graceDaysLeft}')
            : s.trialDaysLeft.replaceAll('{n}', '${sub.daysLeft}');

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              onTap: () => context.push('/subscription'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: color),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.upgradePlan,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
