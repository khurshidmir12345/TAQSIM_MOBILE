import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/models/currency_model.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/ingredient_model.dart';
import '../../domain/providers/setup_provider.dart';

/// Xom ashyo yaratish / tahrirlash uchun modal bottom sheet.
///
/// Forma butun ilova bo'yicha bir xil ko'rinish va xatti-harakatga ega bo'lishi
/// uchun mustaqil widget sifatida ajratilgan. [editing] `null` bo'lsa — yangi
/// xom ashyo yaratadi; aks holda mavjudni tahrirlaydi.
///
/// Qaytaradi: `true` — muvaffaqiyatli saqlandi, `false` / `null` — bekor
/// qilindi yoki xatolik bo'ldi. `ingredientProvider` avtomatik yangilanadi,
/// shuning uchun chaqiruvchi tomonda qo'shimcha refresh kerak emas.
Future<bool> showIngredientFormSheet(
  BuildContext context, {
  IngredientModel? editing,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _IngredientFormSheet(editing: editing),
  );
  return result ?? false;
}

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

String _currencyCodeForId(List<CurrencyModel> currencies, String id) {
  for (final c in currencies) {
    if (c.id == id) return c.code;
  }
  return '';
}

class _IngredientFormSheet extends ConsumerStatefulWidget {
  const _IngredientFormSheet({required this.editing});

  final IngredientModel? editing;

  @override
  ConsumerState<_IngredientFormSheet> createState() =>
      _IngredientFormSheetState();
}

class _IngredientFormSheetState extends ConsumerState<_IngredientFormSheet> {
  late final TextEditingController _nameCtl =
      TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _priceCtl = TextEditingController(
    text: widget.editing != null
        ? _formatEditablePrice(widget.editing!.pricePerUnit)
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

  void _showPriceInfoDialog() {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final sheetShadow = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.1);

    final unitsAsync = ref.watch(ingredientMeasurementUnitsProvider);
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
          return _IngredientFormBody(
            editing: widget.editing,
            nameCtl: _nameCtl,
            priceCtl: _priceCtl,
            units: units,
            currencies: currencies,
            theme: theme,
            unitDisplayName: _unitDisplayName,
            unitInlineName: _unitInlineName,
            onShowPriceInfo: _showPriceInfoDialog,
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

/// Forma tanasi — ma'lumotlar yuklangandan so'ng ochiladi.
class _IngredientFormBody extends ConsumerStatefulWidget {
  const _IngredientFormBody({
    required this.editing,
    required this.nameCtl,
    required this.priceCtl,
    required this.units,
    required this.currencies,
    required this.theme,
    required this.unitDisplayName,
    required this.unitInlineName,
    required this.onShowPriceInfo,
  });

  final IngredientModel? editing;
  final TextEditingController nameCtl;
  final TextEditingController priceCtl;
  final List<MeasurementUnitModel> units;
  final List<CurrencyModel> currencies;
  final ThemeData theme;
  final String Function(MeasurementUnitModel) unitDisplayName;
  final String Function(MeasurementUnitModel) unitInlineName;
  final VoidCallback onShowPriceInfo;

  @override
  ConsumerState<_IngredientFormBody> createState() =>
      _IngredientFormBodyState();
}

class _IngredientFormBodyState extends ConsumerState<_IngredientFormBody> {
  late String _selectedCurrencyId;
  late String _selectedMeasurementUnitId;

  @override
  void initState() {
    super.initState();
    final shopCurId = ref.read(shopProvider).selected?.currencyId;
    _selectedCurrencyId = shopCurId ?? widget.currencies.first.id;
    final def = _defaultUnit(widget.units);
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
    final price = _parseIngredientPrice(widget.priceCtl.text);
    if (name.isEmpty || price <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.snackbarFillAllFields),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    navigator.pop(true);

    final ok = editing == null
        ? await ref.read(ingredientProvider.notifier).create(
              name: name,
              measurementUnitId: _selectedMeasurementUnitId,
              pricePerUnit: price,
              currencyId: _selectedCurrencyId,
            )
        : await ref.read(ingredientProvider.notifier).update(
              id: editing.id,
              name: name,
              measurementUnitId: _selectedMeasurementUnitId,
              pricePerUnit: price,
              currencyId: _selectedCurrencyId,
            );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (editing == null
                  ? s.snackbarIngredientAdded(name)
                  : s.snackbarIngredientUpdated(name))
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing == null
                            ? s.addIngredientModalTitle
                            : s.editIngredientModalTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          height: 1.2,
                        ),
                      ),
                      if (editing == null) ...[
                        const SizedBox(height: 6),
                        Text(
                          s.addIngredientModalSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.35,
                            letterSpacing: 0.1,
                            color:
                                cs.onSurfaceVariant.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (editing == null)
                  PulsingInfoButton(
                    tooltip: s.ingredientPriceInfoTitle,
                    onPressed: widget.onShowPriceInfo,
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
              controller: widget.nameCtl,
              decoration: _fieldDeco(
                cs,
                s.ingredientNameLabel,
                s.ingredientNameHint,
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
                final priceLabel = s.ingredientPricePerUnitLabelDynamic(
                  widget.unitInlineName(selectedUnit),
                );
                return TextField(
                  controller: widget.priceCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                    onPressed: () => Navigator.pop(context, false),
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

/// Sarlavha qatoridagi info — yengil yonib-o'chib turadi (diqqatni jimgina tortadi).
class PulsingInfoButton extends StatefulWidget {
  const PulsingInfoButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  State<PulsingInfoButton> createState() => _PulsingInfoButtonState();
}

class _PulsingInfoButtonState extends State<PulsingInfoButton>
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
