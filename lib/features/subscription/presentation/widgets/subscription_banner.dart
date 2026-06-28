import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/providers/subscription_provider.dart';

/// Dashboard tepasida ko'rinadigan obuna holati banneri.
/// Trial yoki grace davrida ko'rinadi, aks holda bo'sh.
class SubscriptionBanner extends ConsumerWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Billing o'chirilgan bo'lsa — banner umuman ko'rsatilmaydi.
    if (!AppConstants.billingEnabled) return const SizedBox.shrink();

    final s = S.of(context);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return statusAsync.maybeWhen(
      data: (st) {
        final sub = st.subscription;
        if (sub == null) return const SizedBox.shrink();

        final isTrial = sub.status == 'trialing';
        final isGrace = sub.status == 'grace';
        if (!isTrial && !isGrace) return const SizedBox.shrink();

        return _BannerCard(
          isGrace: isGrace,
          title: isGrace
              ? s.graceWarning.replaceAll('{n}', '${sub.graceDaysLeft}')
              : s.trialDaysLeft.replaceAll('{n}', '${sub.daysLeft}'),
          subtitle: s.upgradePlan,
          onTap: () => context.push('/subscription'),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Trial / grace holatida ko'rinadigan professional, minimal banner kartasi.
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.isGrace,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isGrace;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color accent = isGrace ? AppColors.error : AppColors.gold;
    final IconData icon =
        isGrace ? Icons.warning_amber_rounded : Icons.workspace_premium_rounded;

    // Yumshoq, ko'z qiynamaydigan tonal fon — brendga mos.
    final Color bg = accent.withValues(alpha: isDark ? 0.16 : 0.10);
    final Color borderColor = accent.withValues(alpha: isDark ? 0.32 : 0.22);
    final Color titleColor =
        isDark ? theme.colorScheme.onSurface : const Color(0xFF1A1A1A);
    final Color subtitleColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Ikonka rozetkasi.
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.24 : 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                // Matnlar.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // CTA — kichik doiraviy strelka.
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 17,
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
