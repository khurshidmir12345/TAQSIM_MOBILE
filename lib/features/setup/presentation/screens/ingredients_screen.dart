import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/models/currency_model.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/ingredient_model.dart';
import '../../domain/providers/setup_provider.dart';

/// Narx maydoni: bo'shliqlar, vergul, no-break space — `double.tryParse` uchun.
double _parseIngredientPrice(String raw) {
  final t = raw
      .trim()
      .replaceAll(RegExp(r'[\s\u00A0]'), '')
      .replaceAll(',', '.');
  return double.tryParse(t) ?? 0;
}

String _formatEditablePrice(String raw) {
  final d = double.tryParse(raw.replaceAll(',', '.'));
  if (d == null) return raw;
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toString();
}

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

  String _currencyCodeForId(List<CurrencyModel> currencies, String id) {
    for (final c in currencies) {
      if (c.id == id) return c.code;
    }
    return '';
  }

  MeasurementUnitModel? _defaultUnit(List<MeasurementUnitModel> units) {
    for (final u in units) {
      if (u.code == 'kg') return u;
    }
    return units.isEmpty ? null : units.first;
  }

  List<MeasurementUnitModel> _sortedUnits(List<MeasurementUnitModel> units) {
    final list = [...units];
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Foydalanuvchi tanlagan til (uz, uz_CYRL, ru, kk, ky, tr).
  ///
  /// `Localizations.localeOf` `uz_CYRL` ni aniq ajratmagani uchun
  /// to'g'ridan-to'g'ri [localeProvider] dan olamiz.
  String _currentLocaleCode() {
    final async = ref.read(localeProvider);
    return (async.value ?? AppLocale.uz).code;
  }

  /// Chip / label uchun birlik nomi: "Kilogram", "Dona", "Litr", "Metr", ...
  String _unitDisplayName(MeasurementUnitModel u) =>
      u.localizedName(_currentLocaleCode());

  /// Jumla ichida ishlatiladigan kichik harfli birlik nomi:
  /// "1 kilogram narxini kiriting" — "K" emas, "k".
  String _unitInlineName(MeasurementUnitModel u) =>
      _unitDisplayName(u).toLowerCase();

  void _showPriceInfoDialog(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            s.ingredientPriceInfoTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            s.ingredientPriceInfoBody,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.gotIt),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showIngredientSheet(IngredientModel? editing) async {
    final s = S.of(context);
    final nameCtl = TextEditingController(text: editing?.name ?? '');
    final priceCtl = TextEditingController(
      text: editing != null ? _formatEditablePrice(editing.pricePerUnit) : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final unitsAsync = ref.watch(ingredientMeasurementUnitsProvider);
            final curAsync = ref.watch(currenciesProvider);
            final themeSheet = Theme.of(ctx);
            final cs = themeSheet.colorScheme;
            final maxH = MediaQuery.sizeOf(ctx).height * 0.92;
            final sheetShadow = themeSheet.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.1);

            final body = unitsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e'),
              ),
              data: (units) => curAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e'),
                ),
                data: (currencies) {
                  if (units.isEmpty || currencies.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(s.snackbarErrorGeneric),
                    );
                  }
                  final shopCurId = ref.read(shopProvider).selected?.currencyId;
                  var selectedCurrencyId = shopCurId ?? currencies.first.id;
                  final def = _defaultUnit(units);
                  var selectedMeasurementUnitId = def?.id ?? units.first.id;
                  if (editing != null) {
                    if (editing.currencyId != null &&
                        currencies.any((c) => c.id == editing.currencyId)) {
                      selectedCurrencyId = editing.currencyId!;
                    }
                    if (editing.measurementUnitId != null &&
                        units.any((u) => u.id == editing.measurementUnitId)) {
                      selectedMeasurementUnitId = editing.measurementUnitId!;
                    }
                  }
                  final sorted = _sortedUnits(units);

                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      final theme = Theme.of(ctx);
                      const sheetHorizontal = 20.0;

                      InputDecoration fieldDeco(String label, String? hint) {
                        return InputDecoration(
                          labelText: label,
                          hintText: hint,
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: cs.outline.withValues(alpha: 0.18),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: cs.primary.withValues(alpha: 0.65),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
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
                                8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          editing == null
                                              ? s.addIngredientModalTitle
                                              : s.editIngredientModalTitle,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (editing == null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            s.addIngredientModalSubtitle,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 12,
                                              height: 1.35,
                                              letterSpacing: 0.1,
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.62),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (editing == null)
                                    _PulsingInfoButton(
                                      tooltip: s.ingredientPriceInfoTitle,
                                      onPressed: () =>
                                          _showPriceInfoDialog(context),
                                    )
                                  else
                                    const SizedBox(width: 44),
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
                                decoration: fieldDeco(
                                  s.ingredientNameLabel,
                                  s.ingredientNameHint,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autofocus: editing == null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                sheetHorizontal,
                                AppSpacing.md,
                                sheetHorizontal,
                                8,
                              ),
                              child: Text(
                                s.ingredientUnitChipsLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                sheetHorizontal,
                                0,
                                sheetHorizontal,
                                AppSpacing.sm,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    for (final (i, u) in sorted.indexed) ...[
                                      if (i != 0) const SizedBox(width: 8),
                                      FilterChip(
                                        selected: u.id ==
                                            selectedMeasurementUnitId,
                                        showCheckmark: false,
                                        label: Text(
                                          _unitDisplayName(u),
                                          style: theme.textTheme.labelLarge,
                                        ),
                                        onSelected: (_) {
                                          setModalState(() {
                                            selectedMeasurementUnitId = u.id;
                                          });
                                        },
                                        selectedColor: cs.primaryContainer
                                            .withValues(alpha: 0.85),
                                        checkmarkColor: cs.onPrimaryContainer,
                                        side: BorderSide(
                                          color: u.id ==
                                                  selectedMeasurementUnitId
                                              ? cs.primary.withValues(alpha: 0.4)
                                              : cs.outline
                                                  .withValues(alpha: 0.25),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                sheetHorizontal,
                                AppSpacing.md,
                                sheetHorizontal,
                                0,
                              ),
                              child: Builder(
                                builder: (_) {
                                  final selectedUnit = units.firstWhere(
                                    (u) => u.id == selectedMeasurementUnitId,
                                    orElse: () => units.first,
                                  );
                                  final priceLabel =
                                      s.ingredientPricePerUnitLabelDynamic(
                                    _unitInlineName(selectedUnit),
                                  );
                                  return TextField(
                                    controller: priceCtl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: fieldDeco(
                                      priceLabel,
                                      s.sellingPriceHint,
                                    ).copyWith(
                                      suffixIconConstraints:
                                          const BoxConstraints(
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
                                            right: 12,
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
                                                style: theme
                                                    .textTheme.labelLarge
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.75),
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
                                  );
                                },
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
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(s.cancel),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        final name = nameCtl.text.trim();
                                        final price =
                                            _parseIngredientPrice(priceCtl.text);
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
                                                .read(ingredientProvider
                                                    .notifier)
                                                .create(
                                                  name: name,
                                                  measurementUnitId:
                                                      selectedMeasurementUnitId,
                                                  pricePerUnit: price,
                                                  currencyId: selectedCurrencyId,
                                                )
                                            : await ref
                                                .read(ingredientProvider
                                                    .notifier)
                                                .update(
                                                  id: editing.id,
                                                  name: name,
                                                  measurementUnitId:
                                                      selectedMeasurementUnitId,
                                                  pricePerUnit: price,
                                                  currencyId: selectedCurrencyId,
                                                );
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? (editing == null
                                                      ? s.snackbarIngredientAdded(
                                                          name,
                                                        )
                                                      : s.snackbarIngredientUpdated(
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
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
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
                        ),
                      );
                    },
                  );
                },
              ),
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: sheetShadow,
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: body,
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
    final state = ref.watch(ingredientProvider);
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fallbackCur = _currencySuffix(s);

    Widget scaffold = Scaffold(
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
                          onPressed: () => _showIngredientSheet(null),
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
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showIngredientSheet(item),
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
                                          alpha:
                                              theme.brightness ==
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
                                        ? s.snackbarIngredientDeleted(
                                            item.name,
                                          )
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
              onPressed: () => _showIngredientSheet(null),
              tooltip: s.ingredientsAddCta,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 2,
              child: const Icon(Icons.add_rounded),
            ),
    );

    return scaffold;
  }
}

/// Sarlavha qatoridagi info — yengil yonib-o‘chib turadi (diqqatni jimgina tortadi).
class _PulsingInfoButton extends StatefulWidget {
  const _PulsingInfoButton({
    required this.onPressed,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  State<_PulsingInfoButton> createState() => _PulsingInfoButtonState();
}

class _PulsingInfoButtonState extends State<_PulsingInfoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _opacity,
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: cs.primaryContainer.withValues(alpha: 0.65),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.info_outline_rounded,
                size: 22,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
