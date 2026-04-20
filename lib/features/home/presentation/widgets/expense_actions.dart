import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/providers/daily_provider.dart';
import 'expense_actions_sheet.dart';
import 'expense_edit_sheet.dart';

/// Opens an action chooser for an expense and dispatches the resulting
/// edit/delete flow with consistent UX (haptics, undoable delete, error
/// reporting).
///
/// Returns `true` if the underlying expense data changed (edit or delete
/// succeeded) so callers (e.g. local list state holders) can refresh.
Future<bool> showExpenseActions(
  BuildContext context, {
  required WidgetRef ref,
  required ExpenseModel expense,
}) async {
  HapticFeedback.selectionClick();
  final action = await showExpenseActionsSheet(
    context,
    title: expense.displayCategoryLabel,
    subtitle: expense.description?.trim().isNotEmpty == true
        ? expense.description!.trim()
        : null,
  );
  if (action == null || !context.mounted) return false;

  switch (action) {
    case ExpenseAction.edit:
      final updated = await showExpenseEditSheet(
        context,
        ref: ref,
        expense: expense,
      );
      if (updated == null || !context.mounted) return false;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            content: Text(S.of(context).expenseUpdated),
          ),
        );
      return true;

    case ExpenseAction.delete:
      return _confirmAndDelete(context, ref: ref, expense: expense);
  }
}

Future<bool> _confirmAndDelete(
  BuildContext context, {
  required WidgetRef ref,
  required ExpenseModel expense,
}) async {
  final s = S.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.deleteExpense),
      content: Text(s.deleteExpenseConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.delete),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final notifier = ref.read(dailyReportProvider.notifier);
  final repo = ref.read(dailyRepositoryProvider);
  final shop = ref.read(shopProvider).selected;
  if (shop == null) return false;

  notifier.removeExpenseLocally(expense.id);
  HapticFeedback.mediumImpact();

  try {
    await repo.deleteExpense(shop.id, expense.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(s.expenseDeleted),
          ),
        );
    }
    return true;
  } catch (e) {
    notifier.restoreExpenseLocally(expense);
    if (context.mounted) {
      final msg = e is ApiException ? e.message : s.expenseDeleteFailed;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            content: Text(msg),
          ),
        );
    }
    return false;
  }
}
