import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/providers/subscription_provider.dart';

/// Joriy tarif + tugash muddatini ko'rsatadigan karta.
/// Obuna bo'lmasa hech narsa ko'rsatmaydi.
class CurrentPlanCard extends ConsumerWidget {
  const CurrentPlanCard({super.key});

  ({String label, Color color}) _status(S s, String status) => switch (status) {
        'trialing' => (label: s.statusTrialing, color: AppColors.gold),
        'active' => (label: s.statusActive, color: AppColors.primary),
        'grace' => (label: s.statusGraceLabel, color: AppColors.error),
        _ => (label: s.statusExpiredLabel, color: Colors.grey),
      };

  String _date(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return DateFormat('dd.MM.yyyy').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return statusAsync.maybeWhen(
      data: (st) {
        final SubscriptionModel? sub = st.subscription;
        if (sub == null) return const SizedBox.shrink();

        final st0 = _status(s, sub.status);
        final planName = sub.plan?.name ?? (sub.isTrial ? s.trialBadge : '');
        final endDate = _date(sub.endsAt);

        return AppCard(
          color: st0.color.withValues(alpha: 0.08),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: st0.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    color: st0.color, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            planName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: st0.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            st0.label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: st0.color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (endDate.isNotEmpty)
                      Text(
                        '${s.validUntil}: $endDate · ${s.daysLeftShort.replaceAll('{n}', '${sub.daysLeft}')}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
