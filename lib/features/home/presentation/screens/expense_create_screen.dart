import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/expense_api_locale.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/expense_category_option.dart';
import '../../domain/providers/daily_provider.dart';
import '../widgets/expense_category_icon.dart';

class ExpenseCreateScreen extends ConsumerStatefulWidget {
  const ExpenseCreateScreen({super.key});

  @override
  ConsumerState<ExpenseCreateScreen> createState() =>
      _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends ConsumerState<ExpenseCreateScreen> {
  final _amountCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _searchCtl = TextEditingController();
  final _newCategoryCtl = TextEditingController();

  List<ExpenseCategoryOption> _categories = [];
  String? _selectedId;
  bool _loadingCategories = true;
  String? _categoryLoadError;
  bool _isSaving = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCategories);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _amountCtl.dispose();
    _descCtl.dispose();
    _searchCtl.dispose();
    _newCategoryCtl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null) {
      setState(() {
        _loadingCategories = false;
        _categoryLoadError = 'no_shop';
      });
      return;
    }
    setState(() {
      _loadingCategories = true;
      _categoryLoadError = null;
    });
    try {
      final list = await ref.read(dailyRepositoryProvider).fetchExpenseCategories(
            shop.id,
            search: _searchCtl.text.trim().isEmpty ? null : _searchCtl.text,
            locale: expenseApiLocale(context),
          );
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCategories = false;
        if (_selectedId == null ||
            !list.any((c) => c.id == _selectedId)) {
          _selectedId = list.isNotEmpty ? list.first.id : null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
          _categoryLoadError = 'err';
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 380), _loadCategories);
  }

  Future<void> _openAddCategorySheet() async {
    final s = S.of(context);
    _newCategoryCtl.clear();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.expenseAddCategoryTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.expenseCreateSubtitle,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _newCategoryCtl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: s.expenseAddCategoryNameHint,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadius),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    final name = _newCategoryCtl.text.trim();
                    if (name.length < 2) return;
                    Navigator.pop(ctx, true);
                  },
                  child: Text(s.expenseAddCategorySave),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    final name = _newCategoryCtl.text.trim();
    if (name.length < 2) return;

    final shop = ref.read(shopProvider).selected;
    if (shop == null) return;

    try {
      final created = await ref.read(dailyRepositoryProvider).createExpenseCategory(
            shop.id,
            name: name,
            locale: expenseApiLocale(context),
          );
      if (!mounted) return;
      setState(() {
        _categories = [
          created,
          ..._categories.where((c) => c.id != created.id),
        ];
        _selectedId = created.id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.snackbarCategoryAdded(created.name)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : S.of(context).snackbarErrorGeneric;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final s = S.of(context);
    final amount = double.tryParse(_amountCtl.text.trim().replaceAll(',', '.'));
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.expenseSelectCategory),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    final shopId = ref.read(shopProvider).selected!.id;
    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      await ref.read(dailyRepositoryProvider).createExpense(
            shopId,
            category: _selectedId!,
            amount: amount,
            date: today,
            description:
                _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.snackbarErrorGeneric),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppIcons.expense,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                cs.primary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(s.expenseCreateTitle),
          ],
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            s.expenseCreateSubtitle,
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
                onPressed: _openAddCategorySheet,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(s.expenseAddCategory),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_categoryLoadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    _categoryLoadError == 'no_shop'
                        ? s.noBusiness
                        : s.expenseCategoriesLoadError,
                    textAlign: TextAlign.center,
                  ),
                  if (_categoryLoadError != 'no_shop') ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _loadCategories,
                      child: Text(s.tryAgain),
                    ),
                  ],
                ],
              ),
            )
          else if (_categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                s.expenseCategoriesEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            )
          else
            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final sel = _selectedId == c.id;
                  final icon = expenseCategoryIconData(c.icon);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedId = c.id),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadiusLg),
                      child: Ink(
                        width: 88,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sel
                              ? cs.primary.withValues(alpha: 0.12)
                              : cs.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.borderRadiusLg),
                          border: Border.all(
                            color: sel
                                ? cs.primary
                                : cs.outline.withValues(alpha: 0.25),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 28,
                              color: sel ? cs.primary : cs.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: sel
                                        ? cs.primary
                                        : cs.onSurface.withValues(
                                            alpha: 0.85,
                                          ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _amountCtl,
            decoration: InputDecoration(
              labelText: s.expenseAmountLabel,
              suffixText: s.currency,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.expenseSubmit),
          ),
        ],
      ),
    );
  }
}
