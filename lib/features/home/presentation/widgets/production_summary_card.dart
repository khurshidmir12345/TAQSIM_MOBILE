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
    final rq = production.returnsQuantityAllocated.toDouble();
    final ra = production.returnsAmount.toDouble();
    final hasReturns = rq > 0 || ra > 0;

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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${fmt(breadCount)} $productUnit  ·  ${fmt(batch)} $batchCountSuffix',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.45),
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasReturns) ...[
                      const SizedBox(width: 12),
                      _ReturnsInfo(
                        qty: rq,
                        amount: ra,
                        fmt: fmt,
                        productUnit: productUnit,
                        currencyLabel: s.currency,
                        returnedLabel: s.returned,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: s.income,
                        value: '${fmt(netIncome)} ${s.currency}',
                        color: incomeStatColor,
                      ),
                    ),
                    _Sep(cs: cs),
                    Expanded(
                      child: _MiniStat(
                        label: s.expense,
                        value: '${fmt(cost)} ${s.currency}',
                        color: AppColors.error,
                      ),
                    ),
                    _Sep(cs: cs),
                    Expanded(
                      child: _MiniStat(
                        label: s.profit,
                        value: '${fmt(profit)} ${s.currency}',
                        color: isProfit ? AppColors.income : AppColors.error,
                        emphasized: true,
                      ),
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
}

/// Ixcham vozvrat chipi — bir qator, karta balandligiga ta'sir qilmaydi.
///
/// Asosiy qiymat (qty) chip ichida; to'liq ma'lumot tooltipda va detail
/// ekranida ko'rinadi. Amber accent diqqatni tortadi, lekin xalaqit bermaydi.
class _ReturnsInfo extends StatelessWidget {
  const _ReturnsInfo({
    required this.qty,
    required this.amount,
    required this.fmt,
    required this.productUnit,
    required this.currencyLabel,
    required this.returnedLabel,
  });

  final double qty;
  final double amount;
  final String Function(dynamic) fmt;
  final String productUnit;
  final String currencyLabel;
  final String returnedLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasQty = qty > 0;
    final hasAmount = amount > 0;

    final chipBg = AppColors.warning.withValues(alpha: isDark ? 0.16 : 0.10);
    final chipBorder =
        AppColors.warning.withValues(alpha: isDark ? 0.28 : 0.20);
    final chipFg = isDark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFE65100);

    final String chipValue = hasQty
        ? '${fmt(qty)} $productUnit'
        : '${fmt(amount)} $currencyLabel';

    final String? amountStr = (hasQty && hasAmount)
        ? '${fmt(amount)} $currencyLabel'
        : null;

    final String tooltip = amountStr != null
        ? '$returnedLabel: $chipValue · $amountStr'
        : '$returnedLabel: $chipValue';

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: chipBorder, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.undo_rounded,
                    size: 12,
                    color: chipFg,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chipValue,
                    style: TextStyle(
                      color: chipFg,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            if (amountStr != null) ...[
              const SizedBox(height: 3),
              Text(
                amountStr,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.42),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: cs.onSurface.withValues(alpha: 0.08),
      );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: emphasized ? 0.85 : 0.65),
            fontSize: emphasized ? 11 : 10.5,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: emphasized ? 0.2 : 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: emphasized ? 14 : 12,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
