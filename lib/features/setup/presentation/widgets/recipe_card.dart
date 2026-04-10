import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/recipe_model.dart';

/// Hisoblash ro‘yxagi — retsept kartasi (Material 3, 8px grid).
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.formatNumber,
    required this.formatMoney,
    required this.onDelete,
  });

  final RecipeModel recipe;
  final String Function(dynamic value) formatNumber;
  final String Function(dynamic value) formatMoney;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = S.of(context);
    final loc = Localizations.localeOf(context);
    final localeTag = loc.countryCode != null && loc.countryCode!.isNotEmpty
        ? '${loc.languageCode}_${loc.countryCode}'
        : loc.languageCode;

    final unitName = recipe.measurementUnit?.batchDisplayLabel ??
        recipe.measurementUnit?.localizedName(localeTag) ??
        '';

    return Material(
      color: cs.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderRow(
              title: recipe.productDisplayName,
              subtitle: s.recipeRecipeBatchLine(
                unitName.isNotEmpty ? unitName : '·',
                '${recipe.outputQuantity}',
              ),
              onDelete: onDelete,
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
            const SizedBox(height: AppSpacing.sm),
            _StatsRow(
              recipe: recipe,
              s: s,
              formatNumber: formatNumber,
              formatMoney: formatMoney,
              currencyLabel: s.currency,
            ),
            if (recipe.ingredients.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.recipeCardSectionIngredients,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: recipe.ingredients.asMap().entries.map((e) {
                  final i = e.key;
                  final ri = e.value;
                  final (bg, fg) = _ingredientChipPair(theme.brightness, i);
                  return _IngredientMiniChip(
                    label: s.recipeCardIngredientLine(
                      ri.ingredient?.name ?? '—',
                      formatNumber(ri.quantity),
                      ri.ingredient?.displayUnitLine ?? 'kg',
                    ),
                    backgroundColor: bg,
                    foregroundColor: fg,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IngredientMiniChip extends StatelessWidget {
  const _IngredientMiniChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.5,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

(Color, Color) _ingredientChipPair(Brightness brightness, int index) {
  const lightBg = <Color>[
    Color(0xFFE8F4F4),
    Color(0xFFF5EDD0),
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFF3E5F5),
    Color(0xFFE0F2F1),
  ];
  const lightFg = <Color>[
    Color(0xFF145E5E),
    Color(0xFF8B6914),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
  ];
  const darkBg = <Color>[
    Color(0xFF1A3333),
    Color(0xFF3D3520),
    Color(0xFF1A2E40),
    Color(0xFF1B3320),
    Color(0xFF403018),
    Color(0xFF3A2640),
    Color(0xFF0D3330),
  ];
  const darkFg = <Color>[
    Color(0xFF7FD4D4),
    Color(0xFFE8CC6A),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFCC80),
    Color(0xFFCE93D8),
    Color(0xFF80CBC4),
  ];
  final n = index % lightBg.length;
  return brightness == Brightness.dark
      ? (darkBg[n], darkFg[n])
      : (lightBg[n], lightFg[n]);
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.subtitle,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
          ),
          child: Icon(
            Icons.calculate_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: AppColors.error.withValues(alpha: 0.9),
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.recipe,
    required this.s,
    required this.formatNumber,
    required this.formatMoney,
    required this.currencyLabel,
  });

  final RecipeModel recipe;
  final S s;
  final String Function(dynamic value) formatNumber;
  final String Function(dynamic value) formatMoney;
  final String currencyLabel;

  @override
  Widget build(BuildContext context) {
    final out = '${formatNumber(recipe.outputQuantity)} ${s.pcs}';
    final batch = recipe.totalCost != null
        ? '${formatMoney(recipe.totalCost)} $currencyLabel'
        : '—';
    final unit = recipe.costPerBread != null
        ? '${formatMoney(recipe.costPerBread)} $currencyLabel'
        : '—';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Tooltip(
            message: s.recipeCardTooltipOutput,
            child: _StatCell(
              title: s.recipeCardStatTitleOutput,
              value: out,
              accent: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: Tooltip(
            message: s.recipeCardTooltipBatchCost,
            child: _StatCell(
              title: s.recipeCardStatTitleBatchCost,
              value: batch,
              accent: AppColors.gold,
            ),
          ),
        ),
        Expanded(
          child: Tooltip(
            message: s.recipeCardTooltipUnitCost,
            child: _StatCell(
              title: s.recipeCardStatTitleUnitCost,
              value: unit,
              accent: AppColors.info,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: cs.onSurface.withValues(alpha: 0.52),
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent.withValues(alpha: 0.95),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

String formatRecipeNumber(BuildContext context, dynamic value) {
  final n = double.tryParse(value?.toString() ?? '0') ?? 0;
  final loc = Localizations.localeOf(context);
  final tag = loc.countryCode != null && loc.countryCode!.isNotEmpty
      ? '${loc.languageCode}_${loc.countryCode}'
      : loc.languageCode;
  return NumberFormat.decimalPattern(tag).format(n);
}

String formatRecipeMoney(BuildContext context, dynamic value) {
  final n = double.tryParse(value?.toString() ?? '0') ?? 0;
  final loc = Localizations.localeOf(context);
  final tag = loc.countryCode != null && loc.countryCode!.isNotEmpty
      ? '${loc.languageCode}_${loc.countryCode}'
      : loc.languageCode;
  return NumberFormat.decimalPatternDigits(
    locale: tag,
    decimalDigits: 2,
  ).format(n);
}
