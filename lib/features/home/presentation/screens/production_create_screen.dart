import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/providers/terminology_provider.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../setup/domain/models/bread_category_model.dart';
import '../../../setup/domain/models/recipe_model.dart';
import '../../../setup/domain/providers/setup_provider.dart';
import '../../domain/providers/daily_provider.dart';

class ProductionCreateScreen extends ConsumerStatefulWidget {
  const ProductionCreateScreen({super.key});

  @override
  ConsumerState<ProductionCreateScreen> createState() =>
      _ProductionCreateScreenState();
}

class _ProductionCreateScreenState extends ConsumerState<ProductionCreateScreen> {
  static const int _totalSteps = 2;

  final _pageController = PageController();
  final _batchCtl = TextEditingController(text: '1');
  final _searchCtl = TextEditingController();

  int _currentStep = 0;
  String? _selectedCategoryId;
  RecipeModel? _matchedRecipe;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(breadCategoryProvider.notifier).load();
      ref.read(recipeProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _batchCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
  }

  String _fmtNum(BuildContext context, dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
    final tag = _localeTag(context);
    if (n == n.truncateToDouble()) {
      return NumberFormat.decimalPattern(tag).format(n);
    }
    return NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: 2)
        .format(n);
  }

  String _batchUnitLabel(RecipeModel r, BuildContext context) {
    final mu = r.measurementUnit;
    if (mu == null) return '';
    return mu.localizedName(_localeTag(context));
  }

  String _moneySuffix(WidgetRef ref, S s) {
    final sym = ref.read(shopProvider).selected?.currency?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    return s.currency;
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _matchedRecipe = _findRecipe(categoryId);
    });
  }

  List<BreadCategoryModel> _visibleCategories(List<BreadCategoryModel> all) {
    final q = _searchCtl.text.trim().toLowerCase();
    List<BreadCategoryModel> list;
    if (q.isEmpty) {
      list = List<BreadCategoryModel>.from(all);
    } else {
      list = all.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategoryId != null) {
      BreadCategoryModel? sel;
      for (final c in all) {
        if (c.id == _selectedCategoryId) {
          sel = c;
          break;
        }
      }
      if (sel != null) {
        final selectedCat = sel;
        final has = list.any((c) => c.id == selectedCat.id);
        if (!has) {
          list = [selectedCat, ...list];
        }
      }
    }
    return list;
  }

  RecipeModel? _findRecipe(String? categoryId) {
    if (categoryId == null) return null;
    final recipes = ref.read(recipeProvider).items;
    for (final r in recipes) {
      if (r.breadCategory?.id == categoryId) return r;
    }
    return null;
  }

  double get _batchCount => double.tryParse(_batchCtl.text.trim()) ?? 0;

  int get _calculatedOutput =>
      (_matchedRecipe != null)
          ? (_matchedRecipe!.outputQuantity * _batchCount).round()
          : 0;

  double get _calculatedCost {
    if (_matchedRecipe == null) return 0;
    final baseCost = double.tryParse(_matchedRecipe!.totalCost ?? '0') ?? 0;
    return baseCost * _batchCount;
  }

  void _nextStep() {
    final s = S.of(context);
    if (_currentStep == 0) {
      if (_selectedCategoryId == null) {
        _showError(s.productionOutValidationSelectProduct);
        return;
      }
      if (_matchedRecipe == null) {
        _showError(s.productionOutValidationNoRecipe);
        return;
      }
      if (_batchCount <= 0) {
        _showError(s.productionOutValidationBatch);
        return;
      }
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (_selectedCategoryId == null) {
      _showError(s.productionOutValidationSelectProduct);
      return;
    }
    if (_matchedRecipe == null) {
      _showError(s.productionOutValidationNoRecipe);
      return;
    }
    if (_batchCount <= 0) {
      _showError(s.productionOutValidationBatch);
      return;
    }

    setState(() => _isSaving = true);
    final shopId = ref.read(shopProvider).selected!.id;
    final today = DateTime.now().toIso8601String().split('T').first;
    final term = ref.read(terminologyProvider);

    try {
      await ref.read(dailyRepositoryProvider).createProduction(
            shopId,
            recipeId: _matchedRecipe!.id,
            breadCategoryId: _selectedCategoryId!,
            date: today,
            batchCount: _batchCount,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.productionOutSuccess(
                _fmtNum(context, _calculatedOutput),
                term.productUnit,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(dailyReportProvider.notifier).loadToday();
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        _showError(s.snackbarErrorGeneric);
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final term = ref.watch(terminologyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(breadCategoryProvider).items;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.productionOutTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          StepProgressBar(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            labels: [
              s.productionOutStep1,
              s.productionOutStep3,
            ],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(context, s, cs, categories, term.productUnit),
                _buildConfirmStep(context, s, cs, term.productUnit, isDark),
              ],
            ),
          ),
          _buildBottomBar(s, cs),
        ],
      ),
    );
  }

  String _fmtPriceLine(BuildContext context, BreadCategoryModel c, S s) {
    final n = double.tryParse(c.sellingPrice) ?? 0;
    final tag = _localeTag(context);
    final numStr = NumberFormat.decimalPattern(tag).format(n);
    return '$numStr ${c.priceSuffix(s.currency)}';
  }

  Widget _buildStep1(
    BuildContext context,
    S s,
    ColorScheme cs,
    List<BreadCategoryModel> categories,
    String productUnit,
  ) {
    final visible = _visibleCategories(categories);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text(
          s.productionOutStep1Title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          s.productionOutStep1Subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.45,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchCtl,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: s.productionOutSearchHint,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: cs.primary.withValues(alpha: 0.75),
            ),
            suffixIcon: _searchCtl.text.isNotEmpty
                ? IconButton(
                    tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                    onPressed: () {
                      _searchCtl.clear();
                      setState(() {});
                    },
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  )
                : null,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          s.productionOutCategoryLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: cs.primary.withValues(alpha: 0.35),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  s.productCategoriesEmptyTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.productCategoriesEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          )
        else if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                s.productionOutSearchEmpty,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final c = visible[i];
                final selected = _selectedCategoryId == c.id;
                return _CategoryCarouselCard(
                  category: c,
                  selected: selected,
                  priceLine: _fmtPriceLine(context, c, s),
                  onTap: () => _selectCategory(c.id),
                  cs: cs,
                );
              },
            ),
          ),
        if (_matchedRecipe == null && _selectedCategoryId != null) ...[
          const SizedBox(height: AppSpacing.md),
          _WarningCard(
            message: s.productionOutNoRecipeWarning,
            cs: cs,
          ),
        ],
        if (_matchedRecipe != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildBatchSection(context, s, cs, productUnit),
        ],
      ],
    );
  }

  /// Karusel ostida: katta raqam maydoni; birlik alohida — kesilish bo‘lmaydi.
  Widget _buildBatchSection(
    BuildContext context,
    S s,
    ColorScheme cs,
    String productUnit,
  ) {
    final r = _matchedRecipe!;
    final unitLabel = _batchUnitLabel(r, context);
    final unitCode = r.measurementUnit?.batchDisplayLabel ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.productionOutStep2Title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          s.productionOutStep2Subtitle(
            unitLabel.isNotEmpty ? unitLabel : unitCode,
            '${r.outputQuantity}',
            productUnit,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.45,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.2
                      : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _batchCtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: '1',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.22),
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (unitCode.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unitCode,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(
    BuildContext context,
    S s,
    ColorScheme cs,
    String productUnit,
    bool isDark,
  ) {
    final r = _matchedRecipe;
    if (r == null) {
      return const SizedBox.shrink();
    }

    final gradLight = AppColors.cardGradient;
    final gradDark = AppColors.cardGradientDark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text(
          s.productionOutStep3Title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          s.productionOutStep3Subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.45,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? gradDark : gradLight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                s.productionOutSummaryTitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.productionOutTotalOutput(
                  _fmtNum(context, _calculatedOutput),
                  productUnit,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final batchLbl = _batchUnitLabel(r, context);
                        return _SummaryCell(
                          label: batchLbl.isNotEmpty
                              ? batchLbl
                              : (r.measurementUnit?.batchDisplayLabel ?? '·'),
                          value: _fmtNum(context, _batchCount),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _SummaryCell(
                      label: s.productionOutCostLabel,
                      value:
                          '${_fmtNum(context, _calculatedCost)} ${_moneySuffix(ref, s)}',
                    ),
                  ),
                ],
              ),
              if (r.ingredients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.productionOutIngredientsPreview,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...r.ingredients.map((ri) {
                        final qty =
                            (double.tryParse(ri.quantity) ?? 0) * _batchCount;
                        final ing = ri.ingredient;
                        final u = ing?.displayUnitLine ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ing?.name ?? '—',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                u.isNotEmpty
                                    ? '${_fmtNum(context, qty)} $u'
                                    : _fmtNum(context, qty),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(S s, ColorScheme cs) {
    final isLast = _currentStep == _totalSteps - 1;

    return Material(
      color: cs.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSaving ? null : _prevStep,
                    child: Text(s.recipeBack),
                  ),
                if (_currentStep > 0) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving
                        ? null
                        : (isLast ? _save : _nextStep),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isLast ? s.productionOutCta : s.productionOutNext,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCarouselCard extends StatelessWidget {
  const _CategoryCarouselCard({
    required this.category,
    required this.selected,
    required this.priceLine,
    required this.onTap,
    required this.cs,
  });

  final BreadCategoryModel category;
  final bool selected;
  final String priceLine;
  final VoidCallback onTap;
  final ColorScheme cs;

  static const double _cardWidth = 132;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: _cardWidth,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.1)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : cs.outline.withValues(alpha: isDark ? 0.35 : 0.22),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 17,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: cs.onSurface,
                      letterSpacing: -0.15,
                      fontSize: 13,
                    ),
              ),
              Text(
                priceLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message, required this.cs});

  final String message;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
