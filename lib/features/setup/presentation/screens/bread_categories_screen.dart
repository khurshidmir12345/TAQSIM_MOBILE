import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/models/currency_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/bread_category_model.dart';
import '../../domain/providers/setup_provider.dart';

/// Narx maydoni (mahsulot turi).
double _parseCategoryPrice(String raw) {
  final t = raw
      .trim()
      .replaceAll(RegExp(r'[\s\u00A0]'), '')
      .replaceAll(',', '.');
  return double.tryParse(t) ?? 0;
}

String _formatCategoryPriceField(String raw) {
  final d = double.tryParse(raw.replaceAll(',', '.'));
  if (d == null) return raw;
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toString();
}

class BreadCategoriesScreen extends ConsumerStatefulWidget {
  const BreadCategoriesScreen({super.key});

  @override
  ConsumerState<BreadCategoriesScreen> createState() =>
      _BreadCategoriesScreenState();
}

class _BreadCategoriesScreenState
    extends ConsumerState<BreadCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(breadCategoryProvider.notifier).load());
  }

  String _currencySuffix(S s) {
    final cur = ref.watch(shopProvider).selected?.currency;
    final sym = cur?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    final code = cur?.code;
    if (code != null && code.isNotEmpty) return code;
    return s.currency;
  }

  String _currencyCodeForId(List<CurrencyModel> currencies, String id) {
    for (final c in currencies) {
      if (c.id == id) return c.code;
    }
    return '';
  }

  Future<void> _showCategorySheet(BreadCategoryModel? editing) async {
    final s = S.of(context);
    final nameCtl = TextEditingController(text: editing?.name ?? '');
    final priceCtl = TextEditingController(
      text: editing != null
          ? _formatCategoryPriceField(editing.sellingPrice)
          : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(currenciesProvider);
            final cs = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$e'),
                  ),
                  data: (currencies) {
                    if (currencies.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(s.snackbarErrorGeneric),
                      );
                    }
                    final shopCurId = ref.read(shopProvider).selected?.currencyId;
                    var selectedCurrencyId = shopCurId ?? currencies.first.id;
                    if (editing != null &&
                        editing.currencyId != null &&
                        currencies.any((c) => c.id == editing.currencyId)) {
                      selectedCurrencyId = editing.currencyId!;
                    }
                    return StatefulBuilder(
                      builder: (context, setModalState) {
                        final theme = Theme.of(ctx);
                        const sheetHorizontal = 24.0;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: cs.outline.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                sheetHorizontal,
                                16,
                                sheetHorizontal,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    editing == null
                                        ? s.addProductCategoryModalTitle
                                        : s.editProductCategoryModalTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.15,
                                      height: 1.25,
                                    ),
                                  ),
                                  if (editing == null) ...[
                                    SizedBox(height: AppSpacing.sm),
                                    Text(
                                      s.addProductCategoryModalSubtitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                sheetHorizontal,
                                0,
                                sheetHorizontal,
                                0,
                              ),
                              child: TextField(
                                controller: nameCtl,
                                decoration: InputDecoration(
                                  labelText: s.productCategoriesNameLabel,
                                  hintText: s.productCategoriesNameHint,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                autofocus: editing == null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                sheetHorizontal,
                                AppSpacing.md,
                                sheetHorizontal,
                                0,
                              ),
                              child: TextField(
                                controller: priceCtl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: s.sellingPriceLabel,
                                  hintText: s.sellingPriceHint,
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 52,
                                    minHeight: 24,
                                    maxHeight: 40,
                                  ),
                                  suffixIcon: PopupMenuButton<String>(
                                    tooltip: s.currencyPickerLabel,
                                    padding: EdgeInsets.zero,
                                    initialValue: selectedCurrencyId,
                                    onSelected: (v) {
                                      setModalState(
                                        () => selectedCurrencyId = v,
                                      );
                                    },
                                    itemBuilder: (context) => currencies
                                        .map(
                                          (c) => PopupMenuItem<String>(
                                            value: c.id,
                                            child: Text(c.displayLabel),
                                          ),
                                        )
                                        .toList(),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        left: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _currencyCodeForId(
                                              currencies,
                                              selectedCurrencyId,
                                            ),
                                            style: Theme.of(ctx)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                          ),
                                          Icon(
                                            Icons.expand_more_rounded,
                                            size: 18,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.45),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                sheetHorizontal,
                                AppSpacing.lg,
                                sheetHorizontal,
                                AppSpacing.lg,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(s.cancel),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        final name = nameCtl.text.trim();
                                        final price =
                                            _parseCategoryPrice(priceCtl.text);
                                        if (name.isEmpty || price <= 0) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                s.snackbarFillAllFields,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.pop(ctx);
                                        final ok = editing == null
                                            ? await ref
                                                .read(breadCategoryProvider
                                                    .notifier)
                                                .create(
                                                  name: name,
                                                  sellingPrice: price,
                                                  currencyId: selectedCurrencyId,
                                                )
                                            : await ref
                                                .read(breadCategoryProvider
                                                    .notifier)
                                                .update(
                                                  id: editing.id,
                                                  name: name,
                                                  sellingPrice: price,
                                                  currencyId: selectedCurrencyId,
                                                );
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? (editing == null
                                                      ? s.snackbarCategoryAdded(
                                                          name,
                                                        )
                                                      : s.snackbarCategoryUpdated(
                                                          name,
                                                        ))
                                                  : s.snackbarErrorGeneric,
                                            ),
                                            behavior:
                                                SnackBarBehavior.floating,
                                            backgroundColor: ok
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        editing == null
                                            ? s.actionAdd
                                            : s.actionSave,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(breadCategoryProvider);
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = _currencySuffix(s);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.productCategoriesTitle),
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
                        SvgPicture.asset(
                          AppIcons.emptyBasket,
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          s.productCategoriesEmptyTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          s.productCategoriesEmptySubtitle,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () => _showCategorySheet(null),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(s.productCategoriesAddCta),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final cat = state.items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showCategorySheet(cat),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: cs.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.category_rounded,
                                        color: cs.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat.name,
                                            style: TextStyle(
                                              color: cs.onSurface,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${cat.sellingPrice} ${cat.priceSuffix(currency)}',
                                            style: TextStyle(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.5),
                                              fontSize: 13,
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
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () async {
                              final messenger =
                                  ScaffoldMessenger.of(context);
                              final ok = await ref
                                  .read(breadCategoryProvider.notifier)
                                  .delete(cat.id);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? s.snackbarCategoryDeleted(cat.name)
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
              onPressed: () => _showCategorySheet(null),
              tooltip: s.productCategoriesAddCta,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}
