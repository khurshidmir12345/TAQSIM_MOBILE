import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/setup_provider.dart';

/// Sozlamalar UI o'lchamlari (8px grid asosida).
abstract final class _SetupDim {
  static const double cardRadius = 20;
  static const double iconRadius = 16;
  static const double iconBox = 52;
  static const double listBottom = 32;
  static const double headerBottomPad = 18;
  static const double cardPaddingV = 18;
  static const double iconGlyphPad = 12;
  static const double chevronSize = 26;
  static const double backIconSize = 18;
}

/// GoRouter bilan bir xil marshrutlar — bu yerda bitta manba.
abstract final class _SetupRoutes {
  static const breadCategories = '/bread-categories';
  static const ingredients = '/ingredients';
  static const recipes = '/recipes';
  static const shell = '/shell';
}

SystemUiOverlayStyle _setupStatusBarOverlay(Brightness b) =>
    b == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

void _setupPopOrShell(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(_SetupRoutes.shell);
  }
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSetupData);
  }

  void _loadSetupData() {
    ref.read(breadCategoryProvider.notifier).load();
    ref.read(ingredientProvider.notifier).load();
    ref.read(recipeProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.horizontalPadding(context);
    final s = S.of(context);
    final theme = Theme.of(context);
    final shop = ref.watch(shopProvider.select((s) => s.selected));
    final bizKey = shop?.businessType?.key;
    final bizColor = shop?.businessType?.color;

    final bc = ref.watch(breadCategoryProvider);
    final ing = ref.watch(ingredientProvider);
    final rec = ref.watch(recipeProvider);

    final hasCat = bc.items.isNotEmpty;
    final hasIng = ing.items.isNotEmpty;
    final hasRec = rec.items.isNotEmpty;
    final anyLoading = bc.isLoading || ing.isLoading || rec.isLoading;

    final items = _SetupTile.items(
      businessAccent: bizColor,
      bizKey: bizKey,
      s: s,
    );

    final screen = AnnotatedRegion<SystemUiOverlayStyle>(
      value: _setupStatusBarOverlay(theme.brightness),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            _GradientHeader(
              title: s.settings,
              endPadding: pad,
              onBack: () => _setupPopOrShell(context),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  pad,
                  AppSpacing.lg,
                  pad,
                  _SetupDim.listBottom,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  _SetupJourneyPanel(
                    hasCategories: hasCat,
                    hasIngredients: hasIng,
                    hasRecipes: hasRec,
                    isLoading: anyLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...List.generate(items.length, (i) {
                    final e = items[i];
                    final completed = switch (i) {
                      0 => hasCat,
                      1 => hasIng,
                      _ => hasRec,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SetupCard(
                        stepNumber: e.stepNumber,
                        iconAsset: e.iconAsset,
                        route: e.route,
                        accent: e.accent,
                        title: e.title,
                        subtitle: e.subtitle,
                        completed: completed,
                        completedLabel: s.settingsCardCompleted,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return screen;
  }
}

/// Retsept yaratishdagi `_ProgressBar` bilan mos: 3 qadam.
class _SetupJourneyPanel extends StatelessWidget {
  const _SetupJourneyPanel({
    required this.hasCategories,
    required this.hasIngredients,
    required this.hasRecipes,
    required this.isLoading,
  });

  final bool hasCategories;
  final bool hasIngredients;
  final bool hasRecipes;
  final bool isLoading;

  static const int _totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = cs.outline.withValues(alpha: isDark ? 0.35 : 0.2);

    final labels = [
      s.setupJourneyStepLabel1,
      s.setupJourneyStepLabel2,
      s.setupJourneyStepLabel3,
    ];

    final done = [hasCategories, hasIngredients, hasRecipes];
    final allDone = hasCategories && hasIngredients && hasRecipes;

    int emphasizedIndex() {
      if (!hasCategories) return 0;
      if (!hasIngredients) return 1;
      if (!hasRecipes) return 2;
      return 2;
    }

    final emph = emphasizedIndex();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(_SetupDim.cardRadius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    s.setupJourneyTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.setupJourneyHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    height: 1.45,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: List.generate(_totalSteps * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepBefore = i ~/ 2;
                  final filled = done[stepBefore];
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: filled
                            ? AppColors.primary
                            : cs.outline.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }
                final step = i ~/ 2;
                final completed = done[step];
                final isEmph = step == emph && !allDone;
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.primary
                        : isEmph
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: isEmph && !completed
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: completed
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${step + 1}',
                            style: TextStyle(
                              color: isEmph
                                  ? AppColors.primary
                                  : cs.onSurface.withValues(alpha: 0.4),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(_totalSteps, (step) {
                final completed = done[step];
                final isEmph = step == emph && !allDone;
                return Expanded(
                  child: Text(
                    labels[step],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: completed || isEmph
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: isEmph ? FontWeight.w700 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                );
              }),
            ),
            if (allDone) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: AppColors.income,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.setupJourneyAllDone,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.income,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kartalar ma'lumoti — marshrut va matnlar bitta joyda.
@immutable
class _SetupTile {
  const _SetupTile({
    required this.stepNumber,
    required this.iconAsset,
    required this.route,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final int stepNumber;
  final String iconAsset;
  final String route;
  final Color accent;
  final String title;
  final String subtitle;

  static List<_SetupTile> items({
    required Color? businessAccent,
    required String? bizKey,
    required S s,
  }) {
    final firstAccent = businessAccent ?? AppColors.primary;
    return [
      _SetupTile(
        stepNumber: 1,
        iconAsset: AppIcons.breadRound,
        route: _SetupRoutes.breadCategories,
        accent: firstAccent,
        title: s.settingsCardTypesTitle,
        subtitle: s.settingsTypesDesc(bizKey),
      ),
      _SetupTile(
        stepNumber: 2,
        iconAsset: AppIcons.ingredient,
        route: _SetupRoutes.ingredients,
        accent: AppColors.gold,
        title: s.settingsCardIngredientsTitle,
        subtitle: s.settingsIngredientsDesc(bizKey),
      ),
      _SetupTile(
        stepNumber: 3,
        iconAsset: AppIcons.recipe,
        route: _SetupRoutes.recipes,
        accent: AppColors.primaryLight,
        title: s.settingsCardRecipesTitle,
        subtitle: s.settingsRecipesDesc(bizKey),
      ),
    ];
  }
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.title,
    required this.endPadding,
    required this.onBack,
  });

  final String title;
  final double endPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.sm,
          endPadding,
          _SetupDim.headerBottomPad,
        ),
        child: Row(
          children: [
            Material(
              color: cs.surfaceContainerHighest,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: _SetupDim.backIconSize,
                ),
                color: cs.onSurface,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.stepNumber,
    required this.iconAsset,
    required this.route,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.completedLabel,
  });

  final int stepNumber;
  final String iconAsset;
  final String route;
  final Color accent;
  final String title;
  final String subtitle;

  /// Ushbu qadam allaqachon bajarilgan bo‘lsa `true`.
  final bool completed;

  /// `Bajarildi` chip matni (localization'dan).
  final String completedLabel;

  static const Duration _animDuration = Duration(milliseconds: 260);
  static const Curve _animCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final neutralBorder = cs.outline.withValues(alpha: isDark ? 0.35 : 0.22);
    final successBorder =
        AppColors.success.withValues(alpha: isDark ? 0.65 : 0.45);
    final surfaceColor = cs.surface;
    final successTint =
        AppColors.success.withValues(alpha: isDark ? 0.08 : 0.045);

    final borderColor = completed ? successBorder : neutralBorder;
    final backgroundColor =
        completed ? Color.alphaBlend(successTint, surfaceColor) : surfaceColor;

    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : (completed ? AppColors.success : AppColors.primary)
            .withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(_SetupDim.cardRadius),
        child: AnimatedContainer(
          duration: _animDuration,
          curve: _animCurve,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_SetupDim.cardRadius),
            border: Border.all(
              color: borderColor,
              width: completed ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: _SetupDim.cardPaddingV,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(color: accent, asset: iconAsset),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: cs.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant
                              .withValues(alpha: isDark ? 0.9 : 0.88),
                          height: 1.45,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _SetupCardStatus(
                  stepNumber: stepNumber,
                  accent: accent,
                  completed: completed,
                  completedLabel: completedLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Karta ichida o'ng tarafda joylashgan statusli ustun:
/// - Tepada: step raqami (yoki bajarilgan bo'lsa yashil check badge).
/// - Pastda: bajarilgan bo'lsa `Bajarildi` chip; aks holda chevron.
class _SetupCardStatus extends StatelessWidget {
  const _SetupCardStatus({
    required this.stepNumber,
    required this.accent,
    required this.completed,
    required this.completedLabel,
  });

  final int stepNumber;
  final Color accent;
  final bool completed;
  final String completedLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          height: 28,
          child: AnimatedSwitcher(
            duration: _SetupCard._animDuration,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: completed
                ? const _CompletedBadge(key: ValueKey('check'))
                : _StepBadge(
                    key: const ValueKey('number'),
                    number: stepNumber,
                    accent: accent,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSize(
          duration: _SetupCard._animDuration,
          curve: _SetupCard._animCurve,
          alignment: Alignment.topRight,
          child: AnimatedSwitcher(
            duration: _SetupCard._animDuration,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: completed
                ? _CompletedChip(
                    key: const ValueKey('chip'),
                    label: completedLabel,
                  )
                : _CardChevron(key: const ValueKey('chevron'), accent: accent),
          ),
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    super.key,
    required this.number,
    required this.accent,
  });

  final int number;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: accent.withValues(alpha: 0.95),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 17,
      ),
    );
  }
}

class _CompletedChip extends StatelessWidget {
  const _CompletedChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.success.withValues(alpha: isDark ? 0.55 : 0.40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardChevron extends StatelessWidget {
  const _CardChevron({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 2),
      child: Icon(
        Icons.chevron_right_rounded,
        size: _SetupDim.chevronSize,
        color: accent.withValues(alpha: 0.85),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.color, required this.asset});

  final Color color;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _SetupDim.iconBox,
      height: _SetupDim.iconBox,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            Color.lerp(color, Colors.white, 0.15)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_SetupDim.iconRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_SetupDim.iconGlyphPad),
      child: SvgPicture.asset(
        asset,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
