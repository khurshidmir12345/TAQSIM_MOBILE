import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/providers/daily_provider.dart';

/// Bottom sheet which lets the user edit an existing expense (amount and
/// description). Returns the updated [ExpenseModel] or `null` if the user
/// cancels.
Future<ExpenseModel?> showExpenseEditSheet(
  BuildContext context, {
  required WidgetRef ref,
  required ExpenseModel expense,
}) {
  return showModalBottomSheet<ExpenseModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => _ExpenseEditSheet(parentRef: ref, expense: expense),
  );
}

class _ExpenseEditSheet extends ConsumerStatefulWidget {
  const _ExpenseEditSheet({required this.parentRef, required this.expense});

  final WidgetRef parentRef;
  final ExpenseModel expense;

  @override
  ConsumerState<_ExpenseEditSheet> createState() => _ExpenseEditSheetState();
}

class _ExpenseEditSheetState extends ConsumerState<_ExpenseEditSheet> {
  late final TextEditingController _amountCtl;
  late final TextEditingController _descCtl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtl = TextEditingController(
      text: widget.expense.amount % 1 == 0
          ? widget.expense.amount.toStringAsFixed(0)
          : widget.expense.amount.toString(),
    );
    _descCtl = TextEditingController(text: widget.expense.description ?? '');
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = S.of(context);
    final amount = double.tryParse(_amountCtl.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(s.expenseAmountLabel),
        ),
      );
      return;
    }

    final shop = ref.read(shopProvider).selected;
    if (shop == null) return;

    setState(() => _saving = true);
    try {
      final desc = _descCtl.text.trim();
      final updated = await ref.read(dailyRepositoryProvider).updateExpense(
            shop.id,
            widget.expense.id,
            amount: amount,
            description: desc,
          );
      widget.parentRef
          .read(dailyReportProvider.notifier)
          .replaceExpenseLocally(updated);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : s.expenseUpdateFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(msg),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.editExpense,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.expense.displayCategoryLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amountCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.expenseAmountLabel,
                suffixText: s.currency,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descCtl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.expenseDescriptionLabel,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.expenseSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
