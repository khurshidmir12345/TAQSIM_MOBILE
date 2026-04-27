import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/models/recipe_model.dart';
import '../../domain/providers/setup_provider.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(recipeProvider.notifier).load());
  }

  Future<void> _onDeleteRecipe(BuildContext context, RecipeModel recipe) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.recipeDeleteConfirmTitle),
        content: Text(s.recipeDeleteConfirmBody(recipe.productDisplayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await ref.read(recipeProvider.notifier).delete(recipe.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? s.recipeDeletedSnackbar : s.recipeErrorSnackbar),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _refresh() async {
    await ref.read(recipeProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(recipeProvider);
    final cs       = Theme.of(context).colorScheme;
    final s        = S.of(context);
    final Widget scaffold = Scaffold(
      appBar: AppBar(
        title: Text(s.recipeScreenTitle),
        scrolledUnderElevation: 0,
      ),
      body: state.isLoading
          ? const AppLoading()
          : RefreshIndicator(
              onRefresh: _refresh,
              color: cs.primary,
              child: state.items.isEmpty
                  ? _EmptyState(s: s, cs: cs)
                  : ListView.separated(
                      padding: AppSpacing.screenPadding,
                      itemCount: state.items.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final recipe = state.items[index];
                        return RecipeCard(
                          recipe: recipe,
                          formatNumber: (v) => formatRecipeNumber(context, v),
                          formatMoney: (v) => formatRecipeMoney(context, v),
                          onDelete: () => _onDeleteRecipe(context, recipe),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: state.items.isEmpty
          ? null
          : _RecipesBottomDock(
              backLabel: s.backToDashboard,
              addLabel: s.recipeAddCta,
              onBack: () {
                HapticFeedback.selectionClick();
                context.go('/shell');
              },
              onAdd: () {
                HapticFeedback.selectionClick();
                context.push('/recipe-create');
              },
            ),
    );

    return scaffold;
  }
}

/// Retseptlar ekrani pastki "dock"i: chap tomonda — asosiy sahifaga
/// qaytish (primary CTA), o'ng tomonda — yangi retsept qo'shish (circular).
/// Yagona, ixcham, dark/light'da bir xil professional ko'rinish.
class _RecipesBottomDock extends StatelessWidget {
  const _RecipesBottomDock({
    required this.backLabel,
    required this.addLabel,
    required this.onBack,
    required this.onAdd,
  });

  final String backLabel;
  final String addLabel;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  static const double _height = 56;
  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: cs.primary,
                borderRadius: BorderRadius.circular(_radius),
                clipBehavior: Clip.antiAlias,
                shadowColor: cs.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                elevation: isDark ? 0 : 6,
                child: InkWell(
                  onTap: onBack,
                  splashColor: cs.onPrimary.withValues(alpha: 0.1),
                  highlightColor: cs.onPrimary.withValues(alpha: 0.06),
                  child: SizedBox(
                    height: _height,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: 20,
                          color: cs.onPrimary,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            backLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(_radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onAdd,
                child: SizedBox(
                  width: _height,
                  height: _height,
                  child: Tooltip(
                    message: addLabel,
                    child: Icon(
                      Icons.add_rounded,
                      size: 26,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.s,
    required this.cs,
  });

  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            SvgPicture.asset(
              AppIcons.emptyBasket,
              width: 112,
              height: 112,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.recipeEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.recipeEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/recipe-create'),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(s.recipeAddCta),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusLg + 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
