import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/expense_api_locale.dart';
import '../../../home/presentation/widgets/expense_category_icon.dart';
import '../../domain/models/cash_model.dart';
import '../../domain/providers/cash_provider.dart';

/// Kassaga qo'lda kirim yoki chiqim qo'shish.
///
/// Oqim xarajat qo'shishning sinalgan tartibini takrorlaydi — qidiruv,
/// kategoriya kartochkalari, summa, izoh. Farqi faqat rangda va kategoriya
/// ro'yxatida, shuning uchun foydalanuvchi bitta odatni o'rganadi.
class CashEntryCreateScreen extends ConsumerStatefulWidget {
  const CashEntryCreateScreen({super.key, required this.type});

  final CashType type;

  @override
  ConsumerState<CashEntryCreateScreen> createState() =>
      _CashEntryCreateScreenState();
}

class _CashEntryCreateScreenState extends ConsumerState<CashEntryCreateScreen> {
  final _amountCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _searchCtl = TextEditingController();

  String _search = '';
  String? _selectedId;
  bool _isSaving = false;
  Timer? _searchDebounce;

  bool get _isIncome => widget.type == CashType.income;

  Color get _accent => _isIncome ? AppColors.income : AppColors.error;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _amountCtl.dispose();
    _descCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  CashCategoryQuery get _query => CashCategoryQuery(
        type: widget.type,
        locale: expenseApiLocale(context),
        search: _search,
      );

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 380), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  void _reloadCategories() => ref.invalidate(cashCategoriesProvider(_query));

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  // ─── Kategoriya boshqaruvi ─────────────────────────────────────────────

  Future<void> _openCategorySheet([CashCategory? existing]) async {
    final s = S.of(context);
    final controller = TextEditingController(text: existing?.name ?? '');

    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null
                    ? s.expenseAddCategoryTitle
                    : s.cashCategoryRename,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: s.expenseAddCategoryNameHint,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusLg),
                  ),
                ),
                onSubmitted: (v) => Navigator.of(sheetContext).pop(v.trim()),
              ),
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () =>
                    Navigator.of(sheetContext).pop(controller.text.trim()),
                child: Text(s.expenseAddCategorySave),
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();

    if (name == null || name.isEmpty || !mounted) return;

    final actions = ref.read(cashCategoryActionsProvider);

    try {
      if (existing == null) {
        await actions.create(widget.type, name);
      } else {
        await actions.rename(existing.id, name);
      }

      _reloadCategories();
    } catch (_) {
      if (mounted) _snack(s.snackbarErrorGeneric, isError: true);
    }
  }

  Future<void> _confirmDeleteCategory(CashCategory category) async {
    final s = S.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.cashCategoryDeleteTitle),
        content: Text(category.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(cashCategoryActionsProvider).remove(category.id);

      if (_selectedId == category.id) setState(() => _selectedId = null);

      _reloadCategories();
    } catch (_) {
      // Ishlatilayotgan kategoriya o'chirilmaydi — server sababini aytadi.
      if (mounted) _snack(s.cashCategoryInUse, isError: true);
    }
  }

  /// Foydalanuvchi qo'shgan kategoriyani uzoq bosganda amallar chiqadi.
  Future<void> _openCategoryActions(CashCategory category) async {
    if (category.isSystem) return;

    HapticFeedback.selectionClick();
    final s = S.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(s.cashCategoryRename),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openCategorySheet(category);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text(
                s.delete,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDeleteCategory(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Saqlash ───────────────────────────────────────────────────────────

  Future<void> _save() async {
    final s = S.of(context);
    final amount = double.tryParse(_amountCtl.text.trim().replaceAll(',', '.'));

    if (_selectedId == null) {
      _snack(s.expenseSelectCategory, isError: true);

      return;
    }

    if (amount == null || amount <= 0) {
      _snack(s.expenseAmountLabel, isError: true);

      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(cashProvider.notifier).create(
            type: widget.type,
            amount: amount,
            category: _selectedId!,
            description: _descCtl.text,
            date: DateTime.now(),
          );

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _snack(S.of(context).snackbarErrorGeneric, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final categories = ref.watch(cashCategoriesProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 20,
              color: _accent,
            ),
            const SizedBox(width: 8),
            Text(
              _isIncome ? s.cashCreateIncomeTitle : s.cashCreateExpenseTitle,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            _isIncome ? s.cashCreateIncomeSubtitle : s.expenseCreateSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.62),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _searchCtl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: s.expenseCategorySearchHint,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                s.expenseSelectCategory,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openCategorySheet,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(s.expenseAddCategory),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          categories.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    s.expenseCategoriesLoadError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _reloadCategories,
                    child: Text(s.tryAgain),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      s.expenseCategoriesEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : _CategoryStrip(
                    categories: list,
                    selectedId: _selectedId,
                    accent: _accent,
                    onSelect: (id) => setState(() => _selectedId = id),
                    onLongPress: _openCategoryActions,
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _amountCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: s.expenseAmountLabel,
              suffixText: s.currency,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descCtl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s.expenseDescriptionLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(s.expenseSubmit),
          ),
        ],
      ),
    );
  }
}

/// Kategoriya kartochkalari. Foydalanuvchi qo'shganini uzoq bosib
/// tahrirlash yoki o'chirish mumkin — burchagidagi belgi shuni bildiradi.
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedId,
    required this.accent,
    required this.onSelect,
    required this.onLongPress,
  });

  final List<CashCategory> categories;
  final String? selectedId;
  final Color accent;
  final ValueChanged<String> onSelect;
  final ValueChanged<CashCategory> onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final category = categories[i];
          final selected = selectedId == category.id;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(category.id);
              },
              onLongPress: () => onLongPress(category),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              child: Ink(
                width: 88,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.12)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.65),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg),
                  border: Border.all(
                    color:
                        selected ? accent : cs.outline.withValues(alpha: 0.25),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  // Stack bolalari o'z hajmiga siqilib, chapga yopishib
                  // qolmasin — ustun butun kenglikni egallashi kerak.
                  fit: StackFit.expand,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          expenseCategoryIconData(category.icon),
                          size: 28,
                          color: selected
                              ? accent
                              : cs.onSurface.withValues(alpha: 0.75),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: selected
                                        ? accent
                                        : cs.onSurface.withValues(alpha: 0.85),
                                  ),
                        ),
                      ],
                    ),
                    if (!category.isSystem)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
