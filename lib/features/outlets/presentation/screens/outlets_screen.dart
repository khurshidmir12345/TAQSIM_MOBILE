import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/models/outlet_model.dart';
import '../../domain/providers/outlet_provider.dart';
import '../widgets/outlet_avatar.dart';
import '../widgets/outlet_balance_chip.dart';
import '../widgets/outlet_format.dart';

/// Do'konlar ro'yxati — har birida qoldiq ko'rinadi.
class OutletsScreen extends ConsumerStatefulWidget {
  const OutletsScreen({super.key});

  @override
  ConsumerState<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends ConsumerState<OutletsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(outletsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(outletsProvider);
    final cur = outletCurrency(ref, s);

    // Jami qoldiq — sarlavha ostida bitta qatorda.
    final totalOwed = state.items.fold<double>(
      0,
      (sum, o) => sum + o.totals.balance,
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.outletsTitle), scrolledUnderElevation: 0),
      body: state.isLoading
          ? const AppLoading()
          : state.items.isEmpty
          ? EmptyStateWidget(
              icon: Icons.storefront_outlined,
              title: s.outletsEmptyTitle,
              subtitle: s.outletsEmptySubtitle,
              actionLabel: s.outletAdd,
              onAction: () => context.push('/outlets/new'),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(outletsProvider.notifier).load(),
              color: cs.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (totalOwed.abs() > 0.005)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            totalOwed > 0
                                ? s.outletBalanceOwes
                                : s.outletBalancePrepaid,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${outletMoney(context, totalOwed.abs())} $cur',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: totalOwed > 0
                                  ? AppColors.warning
                                  : AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final o in state.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OutletCard(
                        outlet: o,
                        currency: cur,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('/outlets/${o.id}');
                        },
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: state.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/outlets/new'),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.outletAdd),
            ),
    );
  }
}

class _OutletCard extends StatelessWidget {
  const _OutletCard({
    required this.outlet,
    required this.currency,
    required this.onTap,
  });

  final OutletModel outlet;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sub = outlet.address?.trim().isNotEmpty == true
        ? outlet.address!.trim()
        : (outlet.phones.isNotEmpty ? outlet.phones.first : '');

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              OutletAvatar(name: outlet.name, imageUrl: outlet.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutletBalanceChip(
                totals: outlet.totals,
                amountText:
                    '${outletMoney(context, outlet.totals.balance.abs())} $currency',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
