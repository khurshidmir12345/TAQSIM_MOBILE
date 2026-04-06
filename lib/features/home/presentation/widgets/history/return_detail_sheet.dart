import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/l10n/translations.dart';
import '../../../domain/models/bread_return_model.dart';

void showReturnDetailSheet(BuildContext context, BreadReturnModel r) {
  final s = S.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ReturnDetailBody(r: r, title: s.returnDetailTitle),
  );
}

class _ReturnDetailBody extends StatelessWidget {
  const _ReturnDetailBody({
    required this.r,
    required this.title,
  });

  final BreadReturnModel r;
  final String title;

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
  }

  String _fmtMoney(BuildContext context, double n) {
    final tag = _localeTag(context);
    return NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: 2)
        .format(n);
  }

  String _productionValue(S s, BreadReturnProductionSummary p) {
    final b = p.batchCount;
    final batchStr = b == b.truncateToDouble()
        ? b.toInt().toString()
        : b.toStringAsFixed(2);
    return '$batchStr · ${p.breadProduced} ${s.pcs}';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final name = r.breadCategory?.name ?? s.unknown;
    final d = r.date.length >= 10 ? r.date.substring(0, 10) : r.date;
    final dt = DateTime.tryParse(d);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _row(
            context,
            s.returnCategoryLabel,
            name,
            cs,
          ),
          if (r.productionSummary != null)
            _row(
              context,
              s.returnProductionLabel,
              _productionValue(s, r.productionSummary!),
              cs,
            ),
          _row(
            context,
            s.returnQuantityTitle,
            '${r.quantity} ${s.pcs}',
            cs,
          ),
          _row(
            context,
            s.returnPriceLabel,
            '${_fmtMoney(context, r.pricePerUnit)} ${s.currency}',
            cs,
          ),
          _row(
            context,
            s.returnAmount,
            '${_fmtMoney(context, r.totalAmount)} ${s.currency}',
            cs,
            emphasize: true,
          ),
          if (r.reason != null && r.reason!.trim().isNotEmpty)
            _row(context, s.returnReasonLabel, r.reason!.trim(), cs),
          if (dt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              DateFormat.yMMMd(_localeTag(context)).format(dt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value,
    ColorScheme cs, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                    color: emphasize ? AppColors.error : cs.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
