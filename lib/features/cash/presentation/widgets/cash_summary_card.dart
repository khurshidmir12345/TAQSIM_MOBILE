import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/cash_model.dart';

/// Kassaning asosiy kartochkasi.
///
/// Bosh savol bitta — "shu davrda foyda bormi?". Shuning uchun sof natija
/// eng katta shrift bilan tepada, kirim va chiqim esa uning tagida ixcham
/// qator bo'lib turadi. Nisbat chizig'i raqamlarni o'qimasdan ham holatni
/// ko'rsatadi.
class CashSummaryCard extends StatelessWidget {
  const CashSummaryCard({
    super.key,
    required this.summary,
    required this.money,
  });

  final CashSummary summary;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final positive = summary.isProfit;
    final accent = positive ? AppColors.income : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.cashNetResult,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              _Badge(
                label: positive ? s.cashProfit : s.cashLoss,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${positive ? '+' : '−'}${money(summary.net.abs())}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.6,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  s.currency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProportionBar(income: summary.income, expense: summary.expense),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Side(
                  label: s.cashIncome,
                  amount: money(summary.income),
                  count: summary.incomeCount,
                  color: AppColors.income,
                  icon: Icons.south_west_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: cs.outline.withValues(alpha: 0.12),
              ),
              Expanded(
                child: _Side(
                  label: s.cashExpense,
                  amount: money(summary.expense),
                  count: summary.expenseCount,
                  color: AppColors.error,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kirim/chiqim nisbati — raqamsiz ham holat ko'rinsin.
class _ProportionBar extends StatelessWidget {
  const _ProportionBar({required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = income + expense;

    // Ma'lumot yo'q bo'lsa neytral chiziq — bo'sh joy qolib ketmasin.
    final incomeShare = total <= 0 ? 0.5 : income / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: total <= 0
            ? ColoredBox(color: cs.outline.withValues(alpha: 0.15))
            : Row(
                children: [
                  Expanded(
                    flex: (incomeShare * 1000).round().clamp(1, 999),
                    child: const ColoredBox(color: AppColors.income),
                  ),
                  Expanded(
                    flex: ((1 - incomeShare) * 1000).round().clamp(1, 999),
                    child: const ColoredBox(color: AppColors.error),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final String amount;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}
