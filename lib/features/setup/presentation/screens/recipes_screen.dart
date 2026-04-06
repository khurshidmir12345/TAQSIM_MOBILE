import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeProvider);
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.recipeScreenTitle),
        scrolledUnderElevation: 0,
      ),
      body: state.isLoading
          ? const AppLoading()
          : state.items.isEmpty
              ? _EmptyState(s: s, cs: cs)
              : ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: state.items.length,
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
      floatingActionButton: state.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/recipe-create'),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(s.recipeAddCta),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg + 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
