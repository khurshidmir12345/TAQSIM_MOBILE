import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../domain/models/bread_return_model.dart';
import '../../domain/models/production_model.dart';
import '../../domain/providers/daily_provider.dart';

String _normDate(String d) =>
    d.length >= 10 ? d.substring(0, 10) : d.split('T').first;

String _batchFieldText(double v) {
  if (v == v.truncateToDouble()) return v.truncate().toString();
  return v.toString();
}

/// Partiya soni va shu tur bo'yicha bugungi vozvratlar (har biri alohida, o'chirish).
class ProductionEditSheet extends ConsumerStatefulWidget {
  const ProductionEditSheet({
    super.key,
    required this.production,
    required this.onProductionUpdated,
  });

  final ProductionModel production;
  final void Function(ProductionModel updated) onProductionUpdated;

  @override
  ConsumerState<ProductionEditSheet> createState() =>
      _ProductionEditSheetState();
}

class _ProductionEditSheetState extends ConsumerState<ProductionEditSheet> {
  late final TextEditingController _batchController;
  bool _savingBatch = false;
  String? _deletingReturnId;

  @override
  void initState() {
    super.initState();
    _batchController = TextEditingController(
      text: _batchFieldText(widget.production.batchCount),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final date = _normDate(widget.production.date);
      ref.read(dailyReportProvider.notifier).loadDate(date);
    });
  }

  @override
  void didUpdateWidget(covariant ProductionEditSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.production.batchCount != widget.production.batchCount) {
      _batchController.text = _batchFieldText(widget.production.batchCount);
    }
  }

  @override
  void dispose() {
    _batchController.dispose();
    super.dispose();
  }

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

  Future<void> _saveBatch() async {
    final s = S.of(context);
    final raw = _batchController.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v < 0.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.productionOutValidationBatch),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _savingBatch = true);
    final shopId = ref.read(shopProvider).selected!.id;
    final repo = ref.read(dailyRepositoryProvider);
    try {
      final updated = await repo.updateProduction(
        shopId,
        widget.production.id,
        batchCount: v,
      );
      await ref
          .read(dailyReportProvider.notifier)
          .loadDate(_normDate(widget.production.date));
      if (!mounted) return;
      widget.onProductionUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.productionDetailBatchUpdated),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.snackbarErrorGeneric),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingBatch = false);
    }
  }

  Future<void> _confirmDeleteReturn(BreadReturnModel r) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.productionDetailDeleteReturnTitle),
        content: Text(s.productionDetailDeleteReturnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deletingReturnId = r.id);
    final shopId = ref.read(shopProvider).selected!.id;
    final repo = ref.read(dailyRepositoryProvider);
    try {
      await repo.deleteReturn(shopId, r.id);
      await ref
          .read(dailyReportProvider.notifier)
          .loadDate(_normDate(widget.production.date));
      if (!mounted) return;
      final list = ref.read(dailyReportProvider).productions;
      ProductionModel? found;
      for (final p in list) {
        if (p.id == widget.production.id) {
          found = p;
          break;
        }
      }
      if (found != null) widget.onProductionUpdated(found);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.productionDetailReturnDeleted),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.snackbarErrorGeneric),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingReturnId = null);
    }
  }

  List<BreadReturnModel> _returnsForCategory(List<BreadReturnModel> all) {
    final cat = widget.production.breadCategoryId;
    final d = _normDate(widget.production.date);
    final list = all
        .where(
          (r) =>
              r.breadCategoryId == cat && _normDate(r.date) == d,
        )
        .toList();
    list.sort((a, b) {
      final ca = a.createdAt ?? '';
      final cb = b.createdAt ?? '';
      return cb.compareTo(ca);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final returns = _returnsForCategory(ref.watch(dailyReportProvider).returns);

    return Material(
      color: cs.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg + bottomInset,
        ),
        child: Column(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.productionDetailEditSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              s.productionDetailEditBatchLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _batchController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _savingBatch ? null : _saveBatch,
              child: _savingBatch
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.productionDetailEditSaveBatch),
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(color: cs.outline.withValues(alpha: 0.2)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.productionDetailEditReturnsTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (returns.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  s.productionDetailEditNoReturns,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.35,
                  ),
                ),
              )
            else
              ...returns.map((r) {
                final busy = _deletingReturnId == r.id;
                final line =
                    '${r.quantity} ${s.pcs} · ${_fmtMoney(context, r.pricePerUnit)} ${s.currency} → ${_fmtMoney(context, r.totalAmount)} ${s.currency}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              line,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: busy
                                ? null
                                : () => _confirmDeleteReturn(r),
                            icon: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                  ),
                            tooltip: s.delete,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
