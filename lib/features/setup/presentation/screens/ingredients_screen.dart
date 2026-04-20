import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/setup_provider.dart';
import '../widgets/ingredient_form_sheet.dart';

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ingredientProvider.notifier).load());
  }

  String _currencySuffix(S s) {
    final cur = ref.watch(shopProvider).selected?.currency;
    final sym = cur?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    final code = cur?.code;
    if (code != null && code.isNotEmpty) return code;
    return s.currency;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingredientProvider);
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fallbackCur = _currencySuffix(s);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsCardIngredientsTitle),
      ),
      body: state.isLoading
          ? const AppLoading()
          : state.items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SvgPicture.asset(
                              AppIcons.emptyBasket,
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          s.ingredientsEmptyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          s.ingredientsEmptySubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: () => showIngredientFormSheet(context),
                          icon: const Icon(Icons.add_rounded, size: 22),
                          label: Text(s.ingredientsAddCta),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(220, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: state.items.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final unitLine = item.displayUnitLine;
                    return Material(
                      color: cs.surfaceContainerHighest,
                      shadowColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => showIngredientFormSheet(
                                context,
                                editing: item,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer.withValues(
                                          alpha: theme.brightness ==
                                                  Brightness.dark
                                              ? 0.5
                                              : 0.85,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: SvgPicture.asset(
                                        AppIcons.ingredient,
                                        colorFilter: ColorFilter.mode(
                                          cs.onPrimaryContainer,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.pricePerUnit} ${item.priceSuffix(fallbackCur)} · $unitLine',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              foregroundColor: cs.error,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              final messenger =
                                  ScaffoldMessenger.of(context);
                              final ok = await ref
                                  .read(ingredientProvider.notifier)
                                  .delete(item.id);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? s.snackbarIngredientDeleted(item.name)
                                        : s.snackbarErrorGeneric,
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: ok
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: state.items.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => showIngredientFormSheet(context),
              tooltip: s.ingredientsAddCta,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 2,
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}
