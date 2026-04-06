import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/production_model.dart';

/// Asosiy sahifa va tarix — bir xil mahsulot chiqimi kartasi.
class ProductionSummaryCard extends StatelessWidget {
  const ProductionSummaryCard({
    super.key,
    required this.production,
    required this.fmt,
    required this.productUnit,
    required this.batchCountSuffix,
  });

  final ProductionModel production;
  final String Function(dynamic) fmt;
  final String productUnit;
  final String batchCountSuffix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final name = production.breadCategory?.name ?? s.unknown;
    final breadCount = production.breadProduced.toDouble();
    final cost = production.ingredientCost;
    final batch = production.batchCount;
    final netIncome = production.netRevenue;
    final profit = production.netProfit;
    final isProfit = profit >= 0;
    final incomeStatColor =
        netIncome < 0 ? AppColors.error : AppColors.income;
    final rq = production.returnsQuantityAllocated;
    final ra = production.returnsAmount;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/production-detail', extra: production),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_fire_department_outlined,
                        color: cs.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${fmt(breadCount)} $productUnit  ·  ${fmt(batch)} $batchCountSuffix',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.45),
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                          if (rq > 0 || ra > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.undo_rounded,
                                  size: 14,
                                  color: AppColors.error.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    rq > 0 && ra > 0
                                        ? '${s.returned}: ${fmt(rq)} $productUnit · ${fmt(ra)} ${s.currency}'
                                        : rq > 0
                                            ? '${s.returned}: ${fmt(rq)} $productUnit'
                                            : '${s.returned}: ${fmt(ra)} ${s.currency}',
                                    style: TextStyle(
                                      color:
                                          AppColors.error.withValues(alpha: 0.88),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isProfit
                            ? AppColors.income.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isProfit ? '+' : ''}${fmt(profit)}',
                        style: TextStyle(
                          color: isProfit ? AppColors.income : AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    _miniStat(
                      s.income,
                      '${fmt(netIncome)} ${s.currency}',
                      incomeStatColor,
                      cs,
                    ),
                    _sep(cs),
                    _miniStat(
                      s.expense,
                      '${fmt(cost)} ${s.currency}',
                      AppColors.error,
                      cs,
                    ),
                    _sep(cs),
                    _miniStat(
                      s.profit,
                      '${fmt(profit)} ${s.currency}',
                      isProfit ? AppColors.income : AppColors.error,
                      cs,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sep(ColorScheme cs) => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: cs.onSurface.withValues(alpha: 0.06),
      );

  Widget _miniStat(String label, String val, Color c, ColorScheme cs) =>
      Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: c.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
