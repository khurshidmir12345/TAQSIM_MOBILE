import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/models/currency_model.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/bread_category_model.dart';
import '../../domain/providers/setup_provider.dart';

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

MeasurementUnitModel? _defaultProductUnit(List<MeasurementUnitModel> units) {
  for (final u in units) {
    if (u.code == 'ta') return u;
  }
  return units.isEmpty ? null : units.first;
}

List<MeasurementUnitModel> _sortedUnits(List<MeasurementUnitModel> units) {
  final list = [...units];
  list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return list;
}

String _currencyCodeForId(List<CurrencyModel> currencies, String id) {
  for (final c in currencies) {
    if (c.id == id) return c.code;
  }
  return '';
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
    final cur =
        ref.watch(shopProvider.select((s) => s.selected?.currency));
    final sym = cur?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    final code = cur?.code;
    if (code != null && code.isNotEmpty) return code;
    return s.currency;
  }

  String _localeCode() {
    final async = ref.read(localeProvider);
    return (async.value ?? AppLocale.uz).code;
  }

  Future<void> _showCategorySheet(BreadCategoryModel? editing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryFormSheet(editing: editing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(breadCategoryProvider);
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = _currencySuffix(s);
    final localeCode = _localeCode();

    final Widget scaffold = Scaffold(
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
                    final unitName =
                        cat.measurementUnit?.localizedName(localeCode) ?? '';
                    final priceLine = unitName.isEmpty
                        ? '${cat.sellingPrice} ${cat.priceSuffix(currency)}'
                        : '${cat.sellingPrice} ${cat.priceSuffix(currency)} / ${unitName.toLowerCase()}';
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
                                            priceLine,
                                            style: TextStyle(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.55),
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

    return scaffold;
  }
}

// ─── Category Form (modal bottom sheet) ──────────────────────────────────────

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({required this.editing});

  final BreadCategoryModel? editing;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameCtl =
      TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _priceCtl = TextEditingController(
    text: widget.editing != null
        ? _formatCategoryPriceField(widget.editing!.sellingPrice)
        : '',
  );

  @override
  void dispose() {
    _nameCtl.dispose();
    _priceCtl.dispose();
    super.dispose();
  }

  String _currentLocaleCode() {
    final async = ref.read(localeProvider);
    return (async.value ?? AppLocale.uz).code;
  }

  String _unitDisplayName(MeasurementUnitModel u) =>
      u.localizedName(_currentLocaleCode());

  String _unitInlineName(MeasurementUnitModel u) =>
      _unitDisplayName(u).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final sheetShadow = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.1);

    final unitsAsync = ref.watch(productMeasurementUnitsProvider);
    final curAsync = ref.watch(currenciesProvider);

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
          return _CategoryFormBody(
            editing: widget.editing,
            nameCtl: _nameCtl,
            priceCtl: _priceCtl,
            units: units,
            currencies: currencies,
            theme: theme,
            unitDisplayName: _unitDisplayName,
            unitInlineName: _unitInlineName,
          );
        },
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
  }
}

class _CategoryFormBody extends ConsumerStatefulWidget {
  const _CategoryFormBody({
    required this.editing,
    required this.nameCtl,
    required this.priceCtl,
    required this.units,
    required this.currencies,
    required this.theme,
    required this.unitDisplayName,
    required this.unitInlineName,
  });

  final BreadCategoryModel? editing;
  final TextEditingController nameCtl;
  final TextEditingController priceCtl;
  final List<MeasurementUnitModel> units;
  final List<CurrencyModel> currencies;
  final ThemeData theme;
  final String Function(MeasurementUnitModel) unitDisplayName;
  final String Function(MeasurementUnitModel) unitInlineName;

  @override
  ConsumerState<_CategoryFormBody> createState() => _CategoryFormBodyState();
}

class _CategoryFormBodyState extends ConsumerState<_CategoryFormBody> {
  late String _selectedCurrencyId;
  late String _selectedMeasurementUnitId;

  @override
  void initState() {
    super.initState();
    final shopCurId = ref.read(shopProvider).selected?.currencyId;
    _selectedCurrencyId = shopCurId ?? widget.currencies.first.id;
    final def = _defaultProductUnit(widget.units);
    _selectedMeasurementUnitId = def?.id ?? widget.units.first.id;

    final editing = widget.editing;
    if (editing != null) {
      if (editing.currencyId != null &&
          widget.currencies.any((c) => c.id == editing.currencyId)) {
        _selectedCurrencyId = editing.currencyId!;
      }
      if (editing.measurementUnitId != null &&
          widget.units.any((u) => u.id == editing.measurementUnitId)) {
        _selectedMeasurementUnitId = editing.measurementUnitId!;
      }
    }
  }

  InputDecoration _fieldDeco(ColorScheme cs, String label, String? hint) {
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

  Future<void> _submit() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final editing = widget.editing;

    final name = widget.nameCtl.text.trim();
    final price = _parseCategoryPrice(widget.priceCtl.text);
    if (name.isEmpty || price <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.snackbarFillAllFields),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    navigator.pop();

    final ok = editing == null
        ? await ref.read(breadCategoryProvider.notifier).create(
              name: name,
              sellingPrice: price,
              currencyId: _selectedCurrencyId,
              measurementUnitId: _selectedMeasurementUnitId,
            )
        : await ref.read(breadCategoryProvider.notifier).update(
              id: editing.id,
              name: name,
              sellingPrice: price,
              currencyId: _selectedCurrencyId,
              measurementUnitId: _selectedMeasurementUnitId,
            );

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (editing == null
                  ? s.snackbarCategoryAdded(name)
                  : s.snackbarCategoryUpdated(name))
              : s.snackbarErrorGeneric,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = widget.theme;
    final cs = theme.colorScheme;
    const sheetHorizontal = 20.0;
    final sorted = _sortedUnits(widget.units);
    final editing = widget.editing;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing == null
                      ? s.addProductCategoryModalTitle
                      : s.editProductCategoryModalTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                ),
                if (editing == null) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.addProductCategoryModalSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      letterSpacing: 0.1,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.62),
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
              controller: widget.nameCtl,
              decoration: _fieldDeco(
                cs,
                s.productCategoriesNameLabel,
                s.productCategoriesNameHint,
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
                      selected: u.id == _selectedMeasurementUnitId,
                      showCheckmark: false,
                      label: Text(
                        widget.unitDisplayName(u),
                        style: theme.textTheme.labelLarge,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedMeasurementUnitId = u.id;
                        });
                      },
                      selectedColor:
                          cs.primaryContainer.withValues(alpha: 0.85),
                      checkmarkColor: cs.onPrimaryContainer,
                      side: BorderSide(
                        color: u.id == _selectedMeasurementUnitId
                            ? cs.primary.withValues(alpha: 0.4)
                            : cs.outline.withValues(alpha: 0.25),
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
                final selectedUnit = widget.units.firstWhere(
                  (u) => u.id == _selectedMeasurementUnitId,
                  orElse: () => widget.units.first,
                );
                final priceLabel = s.productSellingPriceLabelDynamic(
                  widget.unitInlineName(selectedUnit),
                );
                return TextField(
                  controller: widget.priceCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [DecimalTextInputFormatter()],
                  decoration: _fieldDeco(
                    cs,
                    priceLabel,
                    s.sellingPriceHint,
                  ).copyWith(
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 24,
                      maxHeight: 40,
                    ),
                    suffixIcon: PopupMenuButton<String>(
                      tooltip: s.currencyPickerLabel,
                      padding: EdgeInsets.zero,
                      initialValue: _selectedCurrencyId,
                      onSelected: (v) =>
                          setState(() => _selectedCurrencyId = v),
                      itemBuilder: (context) => widget.currencies
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
                                widget.currencies,
                                _selectedCurrencyId,
                              ),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: cs.onSurface
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: cs.onSurface.withValues(alpha: 0.45),
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(s.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      editing == null ? s.actionAdd : s.actionSave,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
