import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/subscription_plan_model.dart';
import '../../domain/providers/subscription_provider.dart';
import '../widgets/current_plan_card.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _purchasingPlanId;
  bool _yearly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.invalidate(plansProvider);
      ref.read(subscriptionStatusProvider.notifier).refresh();
    });
  }

  String _fmt(double v) => NumberFormat('#,##0', 'uz').format(v);

  Color _planColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var s = hex.replaceFirst('#', '');
    if (s.length == 6) s = 'FF$s';
    final value = int.tryParse(s, radix: 16);
    return value == null ? fallback : Color(value);
  }

  List<String> _features(S s, SubscriptionPlanModel p) {
    final lines = <String>[];

    if (p.limits.products == null) {
      lines.add(s.planFeatureProductsUnlimited);
    } else {
      lines.add(s.planFeatureProducts.replaceAll('{n}', '${p.limits.products}'));
    }

    if (p.limits.shops == null) {
      lines.add(s.planFeatureShopsUnlimited);
    } else {
      lines.add(s.planFeatureShops.replaceAll('{n}', '${p.limits.shops}'));
    }

    final emp = p.limits.employees;
    if (emp == null) {
      lines.add(s.planFeatureEmployeesUnlimited);
    } else if (emp == 0) {
      lines.add(s.planFeatureEmployeesNone);
    } else {
      lines.add(s.planFeatureEmployees.replaceAll('{n}', '$emp'));
    }

    lines.addAll(p.extraFeatures);
    return lines;
  }

  Future<void> _purchase(SubscriptionPlanModel plan) async {
    final s = S.of(context);
    final priceText = '${_fmt(plan.priceLocal)} ${plan.currencyCode}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.purchaseConfirmTitle),
        content: Text(
          s.purchaseConfirmMsg
              .replaceAll('{plan}', plan.name)
              .replaceAll('{price}', priceText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.buy),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _purchasingPlanId = plan.id);
    try {
      await ref.read(subscriptionStatusProvider.notifier).purchase(plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.purchaseSuccess), backgroundColor: AppColors.primary),
      );
      ref.invalidate(plansProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isInsufficientBalance) {
        _showInsufficientBalance();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _purchasingPlanId = null);
    }
  }

  void _showInsufficientBalance() {
    final s = S.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.insufficientBalanceTitle),
        content: Text(s.insufficientBalanceMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet');
            },
            child: Text(s.topUpNow),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final plansAsync = ref.watch(plansProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    final isBlocked = statusAsync.maybeWhen(
      data: (st) => st.subscription?.isBlocked ?? false,
      orElse: () => false,
    );
    final balance = statusAsync.maybeWhen(
      data: (st) => st.balance,
      orElse: () => 0.0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.paywallTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(plansProvider);
          await ref.read(subscriptionStatusProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Header(isBlocked: isBlocked, balance: _fmt(balance)),
            const SizedBox(height: AppSpacing.md),
            const CurrentPlanCard(),
            const SizedBox(height: AppSpacing.md),
            _PeriodToggle(
              yearly: _yearly,
              onChanged: (v) => setState(() => _yearly = v),
            ),
            const SizedBox(height: AppSpacing.md),
            plansAsync.when(
              loading: () => const SkeletonLoader(itemCount: 3, itemHeight: 220),
              error: (e, _) => ErrorRetryWidget(
                message: e is ApiException ? e.message : e.toString(),
                onRetry: () => ref.invalidate(plansProvider),
              ),
              data: (plans) {
                final period = _yearly ? 'yearly' : 'monthly';
                final visible =
                    plans.where((p) => p.billingPeriod == period).toList();

                if (visible.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyStateWidget(
                      icon: Icons.event_busy_outlined,
                      title: _yearly ? s.yearlyNotAvailable : s.noActivePlan,
                      subtitle: _yearly ? s.yearlyNotAvailableDesc : null,
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final plan in visible) ...[
                      _PlanCard(
                        plan: plan,
                        yearly: _yearly,
                        color: _planColor(plan.color, cs.primary),
                        priceText: _fmt(plan.priceLocal),
                        features: _features(s, plan),
                        isLoading: _purchasingPlanId == plan.id,
                        disabled: _purchasingPlanId != null,
                        onBuy: () => _purchase(plan),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isBlocked;
  final String balance;

  const _Header({required this.isBlocked, required this.balance});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    if (isBlocked) {
      return AppCard(
        color: AppColors.error.withValues(alpha: 0.10),
        child: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.paywallBlockedTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.paywallBlockedSubtitle,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.paywallSubtitle,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              '${s.balance}: $balance UZS',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onChanged;

  const _PeriodToggle({required this.yearly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Row(
        children: [
          _segment(context, s.billingMonthly, !yearly, () => onChanged(false)),
          _segment(context, s.billingYearly, yearly, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius - 4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool yearly;
  final Color color;
  final String priceText;
  final List<String> features;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onBuy;

  const _PlanCard({
    required this.plan,
    required this.yearly,
    required this.color,
    required this.priceText,
    required this.features,
    required this.isLoading,
    required this.disabled,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(
          color: plan.isPopular ? color : cs.outlineVariant,
          width: plan.isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.borderRadiusLg),
                  topRight: Radius.circular(AppSpacing.borderRadiusLg),
                ),
              ),
              child: Text(
                s.planMostPopular,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      priceText,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'UZS${yearly ? s.planPerYear : s.planPerMonth}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '≈ \$${plan.priceUsd.toStringAsFixed(plan.priceUsd % 1 == 0 ? 0 : 1)}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final line in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(line)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: s.buy,
                  isLoading: isLoading,
                  onPressed: disabled && !isLoading ? null : onBuy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
