import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/providers/setup_provider.dart';
import 'bread_categories_screen.dart';
import 'ingredients_screen.dart';
import 'recipes_screen.dart';

/// Sozlamalar UI o'lchamlari (8px grid asosida).
abstract final class _SetupDim {
  static const double cardRadius = 20;
  static const double headerBottomPad = 18;
  static const double backIconSize = 18;
}

/// GoRouter bilan bir xil marshrutlar — bu yerda bitta manba.
abstract final class _SetupRoutes {
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

/// Sozlamalar bo'limlari — har biri alohida sahifa.
enum _SetupSection { products, ingredients, recipes }

class _SetupScreenState extends ConsumerState<SetupScreen> {
  _SetupSection _section = _SetupSection.products;

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

    final bc = ref.watch(breadCategoryProvider);
    final ing = ref.watch(ingredientProvider);
    final rec = ref.watch(recipeProvider);

    final hasCat = bc.items.isNotEmpty;
    final hasIng = ing.items.isNotEmpty;
    final hasRec = rec.items.isNotEmpty;
    final anyLoading = bc.isLoading || ing.isLoading || rec.isLoading;

    // Barcha bosqich tugagach ko'rsatkich kerak emas — ekranni band qilmasin.
    final allDone = hasCat && hasIng && hasRec;


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
            Padding(
              padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, 0),
              child: _SectionTabs(
                section: _section,
                onChanged: (v) => setState(() => _section = v),
              ),
            ),
            if (!allDone)
              Padding(
                padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, 0),
                child: _SetupJourneyPanel(
                  hasCategories: hasCat,
                  hasIngredients: hasIng,
                  hasRecipes: hasRec,
                  isLoading: anyLoading,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              // IndexedStack bo'limlar holatini saqlaydi — qaytib kelganda
              // ro'yxat boshidan yuklanmaydi.
              child: IndexedStack(
                index: _section.index,
                children: const [
                  BreadCategoriesScreen(embedded: true),
                  IngredientsScreen(embedded: true),
                  RecipesScreen(embedded: true),
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

/// Bo'lim tanlagichi — kassadagi davr tanlagichi bilan bir xil uslubda.
class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.section, required this.onChanged});

  final _SetupSection section;
  final ValueChanged<_SetupSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_SetupSection>(
        segments: [
          ButtonSegment(
            value: _SetupSection.products,
            label: Text(s.setupJourneyStepLabel1),
          ),
          ButtonSegment(
            value: _SetupSection.ingredients,
            label: Text(s.setupJourneyStepLabel2),
          ),
          ButtonSegment(
            value: _SetupSection.recipes,
            label: Text(s.setupJourneyStepLabel3),
          ),
        ],
        selected: {section},
        onSelectionChanged: (set) {
          HapticFeedback.selectionClick();
          onChanged(set.first);
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStatePropertyAll(
            Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
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

