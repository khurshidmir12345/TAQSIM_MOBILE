import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/daily_repository.dart';
import '../../domain/providers/daily_provider.dart';
import '../../../setup/domain/models/ingredient_model.dart';
import '../../../setup/domain/models/recipe_model.dart'
    show RecipeIngredientModel;
import '../../domain/models/production_model.dart';
import '../widgets/production_edit_sheet.dart';

/// Bugungi partiya — ingredientlar bo'yicha batafsil (gramm / summa).
class ProductionDetailScreen extends ConsumerStatefulWidget {
  const ProductionDetailScreen({super.key, required this.production});

  final ProductionModel production;

  @override
  ConsumerState<ProductionDetailScreen> createState() =>
      _ProductionDetailScreenState();
}

class _ProductionDetailScreenState extends ConsumerState<ProductionDetailScreen> {
  late ProductionModel _production;

  @override
  void initState() {
    super.initState();
    _production = widget.production;
  }

  Future<void> _confirmDeleteProduction() async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.productionDetailDeleteProductionTitle),
        content: Text(s.productionDetailDeleteProductionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final shop = ref.read(shopProvider).selected;
    if (shop == null) return;

    try {
      await ref.read(dailyRepositoryProvider).deleteProduction(
            shop.id,
            _production.id,
          );
      if (!mounted) return;
      await ref.read(dailyReportProvider.notifier).loadDate(_production.date);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.productionDetailProductionDeleted),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg =
          e is ApiException ? e.message : S.of(context).snackbarErrorGeneric;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
  }

  String _fmtNum(BuildContext context, double n, {int maxFrac = 3}) {
    final tag = _localeTag(context);
    if (n == n.truncateToDouble() && maxFrac >= 0) {
      return NumberFormat.decimalPattern(tag).format(n);
    }
    return NumberFormat.decimalPatternDigits(
      locale: tag,
      decimalDigits: maxFrac,
    ).format(n);
  }

  String _fmtMoney(BuildContext context, double n) {
    final tag = _localeTag(context);
    return NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: 2)
        .format(n);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipe = _production.recipe;
    final ingredients = recipe?.ingredients ?? [];
    final batchCount = _production.batchCount;
    final name = _production.breadCategory?.name ?? recipe?.productDisplayName ?? s.unknown;
    final unitCode = recipe?.measurementUnit?.batchDisplayLabel ?? '';

    final bread = _production.breadProduced.toDouble();
    final cost = _production.ingredientCost;
    final income = _production.netRevenue;
    final profit = _production.netProfit;
    final returnQtyToday = _production.returnsQuantityAllocated;
    final returnAmtToday = _production.returnsAmount;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.build_rounded),
                tooltip: s.productionDetailEdit,
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (ctx) => ProductionEditSheet(
                      production: _production,
                      onProductionUpdated: (p) {
                        setState(() => _production = p);
                      },
                    ),
                  );
                },
              ),
              IconButton(
                style: IconButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: s.productionDetailDeleteProductionTitle,
                onPressed: _confirmDeleteProduction,
              ),
            ],
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.productionDetailTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _HeroSummary(
                cs: cs,
                isDark: isDark,
                s: s,
                fmt: (v) => _fmtMoney(context, v),
                batchCount: batchCount,
                batchUnit: unitCode.isNotEmpty ? unitCode : '—',
                bread: bread,
                returnQtyToday: returnQtyToday,
                returnsAmountToday: returnAmtToday,
                flourKg: _production.flourUsedKg,
                ingredientCost: cost,
                income: income,
                profit: profit,
                fmtNum: (v, {int maxFrac = 3}) =>
                    _fmtNum(context, v, maxFrac: maxFrac),
              ),
            ),
          ),
          if (ingredients.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  s.productionDetailNoIngredients,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: _IngredientsSummaryCard(
                  ingredients: ingredients,
                  batchCount: batchCount,
                  cs: cs,
                  isDark: isDark,
                  s: s,
                  fmtNum: (v, {int maxFrac = 3}) =>
                      _fmtNum(context, v, maxFrac: maxFrac),
                  fmtMoney: (v) => _fmtMoney(context, v),
                  gramsLine: (ing, qtyTotal) =>
                      _gramsLine(context, s, ing, qtyTotal),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  String? _gramsLine(
    BuildContext context,
    S s,
    IngredientModel? ing,
    double qtyTotal,
  ) {
    if (ing == null) return null;
    final code = ing.measurementUnit?.code ?? '';
    if (code == 'kg') {
      final g = qtyTotal * 1000;
      return s.productionDetailGrams(_fmtNum(context, g, maxFrac: 0));
    }
    if (code == 'g') {
      return s.productionDetailGrams(_fmtNum(context, qtyTotal, maxFrac: 0));
    }
    return null;
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.cs,
    required this.isDark,
    required this.s,
    required this.fmt,
    required this.batchCount,
    required this.batchUnit,
    required this.bread,
    required this.returnQtyToday,
    required this.returnsAmountToday,
    required this.flourKg,
    required this.ingredientCost,
    required this.income,
    required this.profit,
    required this.fmtNum,
  });

  final ColorScheme cs;
  final bool isDark;
  final S s;
  final String Function(double) fmt;
  final double batchCount;
  final String batchUnit;
  final double bread;
  final int returnQtyToday;
  final double returnsAmountToday;
  final double? flourKg;
  final double ingredientCost;
  final double income;
  final double profit;
  final String Function(double, {int maxFrac}) fmtNum;

  @override
  Widget build(BuildContext context) {
    final profitPositive = profit >= 0;
    final border = cs.outline.withValues(alpha: isDark ? 0.35 : 0.2);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: isDark ? 0.18 : 0.08),
            cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 4),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.productionDetailSummary,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _row(
              context,
              Icons.layers_outlined,
              s.productionDetailBatch,
              '${fmtNum(batchCount)} $batchUnit',
            ),
            _row(
              context,
              Icons.bakery_dining_outlined,
              s.productionDetailOutput,
              '${fmtNum(bread, maxFrac: 0)} ${s.pcs}',
            ),
            if (returnQtyToday > 0 || returnsAmountToday > 0)
              _row(
                context,
                Icons.undo_rounded,
                s.productionDetailReturnToday,
                returnQtyToday > 0 && returnsAmountToday > 0
                    ? '${fmtNum(returnQtyToday.toDouble(), maxFrac: 0)} ${s.pcs} · ${fmt(returnsAmountToday)} ${s.currency}'
                    : returnQtyToday > 0
                        ? '${fmtNum(returnQtyToday.toDouble(), maxFrac: 0)} ${s.pcs}'
                        : '${fmt(returnsAmountToday)} ${s.currency}',
                valueColor: AppColors.error,
              ),
            if (flourKg != null && flourKg! > 0)
              _row(
                context,
                Icons.grass_outlined,
                s.productionDetailFlour,
                '${fmtNum(flourKg!)} kg',
              ),
            _row(
              context,
              Icons.payments_outlined,
              s.productionDetailIngredientCost,
              '${fmt(ingredientCost)} ${s.currency}',
              valueColor: AppColors.warning,
            ),
            Divider(height: AppSpacing.lg, color: cs.outline.withValues(alpha: 0.2)),
            _row(
              context,
              Icons.trending_up_rounded,
              s.productionDetailSalesEstimate,
              '${fmt(income)} ${s.currency}',
              valueColor: AppColors.income,
            ),
            _row(
              context,
              profitPositive ? Icons.add_chart_rounded : Icons.trending_down_rounded,
              s.profit,
              '${profitPositive ? '+' : ''}${fmt(profit)} ${s.currency}',
              valueColor: profitPositive ? AppColors.income : AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    height: 1.25,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? cs.onSurface,
                ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

/// Yuqoridagi «Bugungi yopilgan partiya» kartasiga o‘xshash bitta konteyner,
/// ichida har bir ingredient — 2 qator (nom + summa/miqdor, keyin birlik narxi).
class _IngredientsSummaryCard extends StatelessWidget {
  const _IngredientsSummaryCard({
    required this.ingredients,
    required this.batchCount,
    required this.cs,
    required this.isDark,
    required this.s,
    required this.fmtNum,
    required this.fmtMoney,
    required this.gramsLine,
  });

  final List<RecipeIngredientModel> ingredients;
  final double batchCount;
  final ColorScheme cs;
  final bool isDark;
  final S s;
  final String Function(double, {int maxFrac}) fmtNum;
  final String Function(double) fmtMoney;
  final String? Function(IngredientModel? ing, double qtyTotal) gramsLine;

  @override
  Widget build(BuildContext context) {
    final border = cs.outline.withValues(alpha: isDark ? 0.35 : 0.2);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: isDark ? 0.18 : 0.08),
            cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 4),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.productionDetailBreakdown,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < ingredients.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppSpacing.lg,
                  thickness: 1,
                  color: cs.outline.withValues(alpha: 0.18),
                ),
              _IngredientCompactBlock(
                ri: ingredients[i],
                batchCount: batchCount,
                cs: cs,
                s: s,
                fmtNum: fmtNum,
                fmtMoney: fmtMoney,
                gramsLine: gramsLine,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IngredientCompactBlock extends StatelessWidget {
  const _IngredientCompactBlock({
    required this.ri,
    required this.batchCount,
    required this.cs,
    required this.s,
    required this.fmtNum,
    required this.fmtMoney,
    required this.gramsLine,
  });

  final RecipeIngredientModel ri;
  final double batchCount;
  final ColorScheme cs;
  final S s;
  final String Function(double, {int maxFrac}) fmtNum;
  final String Function(double) fmtMoney;
  final String? Function(IngredientModel? ing, double qtyTotal) gramsLine;

  @override
  Widget build(BuildContext context) {
    final ing = ri.ingredient;
    final qtyPerRecipe = double.tryParse(ri.quantity) ?? 0;
    final qtyTotal = qtyPerRecipe * batchCount;
    final linePerRecipe =
        double.tryParse(ri.lineCost ?? '') ??
        (qtyPerRecipe * (double.tryParse(ing?.pricePerUnit ?? '0') ?? 0));
    final lineTotal = linePerRecipe * batchCount;
    final unit = ing?.displayUnitLine ?? '';
    final qtyStr = unit.isNotEmpty
        ? '${fmtNum(qtyTotal)} $unit'
        : fmtNum(qtyTotal);
    final gLine = gramsLine(ing, qtyTotal);
    final pricePerUnit = double.tryParse(ing?.pricePerUnit ?? '0') ?? 0;
    final unitForPrice = ing?.measurementUnit?.name.trim();
    final priceRight = unitForPrice != null && unitForPrice.isNotEmpty
        ? '$unitForPrice / ${fmtMoney(pricePerUnit)} ${s.currency}'
        : '${fmtMoney(pricePerUnit)} ${s.currency} / ${unit.isNotEmpty ? unit : '—'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.3,
                        color: cs.onSurface.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                  children: [
                    TextSpan(text: ing?.name ?? '—'),
                    TextSpan(
                      text: ' / ${s.productionDetailOneRecipeBatch}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              flex: 0,
              child: Text(
                '${fmtMoney(lineTotal)} ${s.currency} / $qtyStr',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: cs.onSurface,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                s.productionDetailPricePerUnit,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Flexible(
              flex: 0,
              child: Text(
                priceRight,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
              ),
            ),
          ],
        ),
        if (gLine != null) ...[
          const SizedBox(height: 4),
          Text(
            gLine,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}
