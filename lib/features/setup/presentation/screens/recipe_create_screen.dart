import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../domain/models/bread_category_model.dart';
import '../../domain/models/ingredient_model.dart';
import '../../domain/providers/setup_provider.dart';
import '../widgets/ingredient_form_sheet.dart';

class RecipeCreateScreen extends ConsumerStatefulWidget {
  const RecipeCreateScreen({super.key});

  @override
  ConsumerState<RecipeCreateScreen> createState() =>
      _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen> {
  /// To‘liq kenglik — `viewportFraction` < 1 bo‘lsa qo‘shni sahifa/karta yon tomonda ko‘rinadi.
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 3;

  String? _selectedCategoryId;
  String? _measurementUnitId;

  final _outputCtl = TextEditingController();
  final _outputFocusNode = FocusNode();
  final List<_IngredientEntry> _ingredientEntries = [
    _IngredientEntry(quantityController: TextEditingController()),
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(breadCategoryProvider.notifier).load();
      ref.read(ingredientProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _outputCtl.dispose();
    _outputFocusNode.dispose();
    super.dispose();
  }

  void _nextStep() {
    final s = S.of(context);
    if (_currentStep == 0 && _selectedCategoryId == null) {
      _showError(s.recipeValidationSelectProduct);
      return;
    }
    if (_currentStep == 1) {
      final batchAsync = ref.read(recipeBatchUnitsProvider);
      final units = switch (batchAsync) {
        AsyncData<List<MeasurementUnitModel>>(:final value) => value,
        _ => <MeasurementUnitModel>[],
      };
      if (units.isEmpty) {
        _showError(s.recipeValidationBatch);
        return;
      }
      if (_measurementUnitId == null) {
        _showError(s.recipeValidationBatch);
        return;
      }
      final output = int.tryParse(_outputCtl.text.trim()) ?? 0;
      if (output <= 0) {
        _showError(s.recipeValidationOutput);
        return;
      }
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (_currentStep == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _outputFocusNode.requestFocus();
        });
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredientEntries.add(_IngredientEntry(
        quantityController: TextEditingController(),
      ));
    });
  }

  /// Step 1 da kartaga bosilganda: tanlashni ko'rsatish uchun qisqa pauza,
  /// so'ng avtomatik ravishda 2-qadamga o'tish.
  void _onCategoryTap(String categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      if (_currentStep != 0) return;
      _nextStep();
    });
  }

  /// Foydalanuvchi tanlagan til kodi (uz, uz_CYRL, ru, kk, ky, tr).
  ///
  /// `Localizations.localeOf` `uz_CYRL` ni aniq ajratmaydi,
  /// shuning uchun ilovaning o'z [localeProvider] idan olinadi.
  String _currentLocaleCode() {
    final async = ref.read(localeProvider);
    return (async.value ?? AppLocale.uz).code;
  }

  /// Partiya birligi uchun to'liq lokallashgan nom ("Blok", "Qop", "KG", ...).
  ///
  /// DB'da ba'zi nomlarda texnik qavs ("KG (partiya)") bor — UI'da u
  /// chalg'ituvchi bo'lgani uchun bu yerda tozalaymiz. Foydalanuvchi faqat
  /// asosiy nomni ko'radi.
  String _batchUnitDisplayName(MeasurementUnitModel u) {
    final raw = u.localizedName(_currentLocaleCode());
    final cleaned =
        raw.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    if (cleaned.isNotEmpty) return cleaned;
    return u.batchDisplayLabel;
  }

  /// Jumla ichida ishlatiladigan kichik harfli variant
  /// ("1 blokdan ...", "1 qopdan ...").
  String _batchUnitInlineName(MeasurementUnitModel u) =>
      _batchUnitDisplayName(u).toLowerCase();

  /// Tanlangan partiya birligini `units` ro'yxatidan topadi.
  MeasurementUnitModel? _selectedBatchUnit(
    List<MeasurementUnitModel> units,
  ) {
    if (_measurementUnitId == null || units.isEmpty) return null;
    for (final u in units) {
      if (u.id == _measurementUnitId) return u;
    }
    return null;
  }

  /// Xom ashyo miqdori input suffixi: xom ashyo yaratilishida tanlangan
  /// o'lchov birligining qisqa kodi, birinchi harfi katta qilib ko'rsatiladi
  /// ("Kg", "G", "Ta", "L", "Ml", "M", ...).
  ///
  /// Input ichida joy tor bo'lgani uchun to'liq nom emas, qisqa kod afzal —
  /// u universal va barcha tillarda tushunarli.
  String? _quantitySuffix(
    _IngredientEntry entry,
    List<IngredientModel> allIngredients,
  ) {
    final id = entry.ingredientId;
    if (id == null) return null;
    for (final ing in allIngredients) {
      if (ing.id != id) continue;
      return _capitalizeUnitCode(ing.displayUnitLine);
    }
    return null;
  }

  /// Birlik kodini toza "Capitalized" formatga keltiradi:
  /// `kg` → `Kg`, `ml` → `Ml`, `m` → `M`. Bo'sh/non-alpha kiritma
  /// bo'lsa asl qiymatini qaytaradi.
  String _capitalizeUnitCode(String code) {
    if (code.isEmpty) return code;
    final first = code.substring(0, 1).toUpperCase();
    final rest = code.length > 1 ? code.substring(1).toLowerCase() : '';
    return '$first$rest';
  }

  String _fmtNum(BuildContext context, dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
    final l = Localizations.localeOf(context);
    final tag = l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
    return NumberFormat.decimalPattern(tag).format(n);
  }

  Future<void> _save() async {
    final s = S.of(context);
    final validEntries = _ingredientEntries
        .where((e) => e.ingredientId != null)
        .toList();

    if (validEntries.isEmpty) {
      _showError(s.recipeValidationIngredients);
      return;
    }

    final ids = validEntries.map((e) => e.ingredientId).toSet();
    if (ids.length != validEntries.length) {
      _showError(s.recipeValidationDuplicateIngredient);
      return;
    }

    final batchAsync = ref.read(recipeBatchUnitsProvider);
    final units = switch (batchAsync) {
      AsyncData<List<MeasurementUnitModel>>(:final value) => value,
      _ => <MeasurementUnitModel>[],
    };
    if (_measurementUnitId == null || units.isEmpty) {
      _showError(s.recipeValidationBatch);
      return;
    }

    setState(() => _isSaving = true);

    final categories = ref.read(breadCategoryProvider).items;
    BreadCategoryModel? cat;
    for (final c in categories) {
      if (c.id == _selectedCategoryId) {
        cat = c;
        break;
      }
    }
    final name = cat?.name ?? '';

    final ingredients = validEntries
        .map((e) => {
              'ingredient_id': e.ingredientId!,
              'quantity': double.tryParse(e.quantityController.text) ?? 0,
            })
        .toList();

    final ok = await ref.read(recipeProvider.notifier).create(
          breadCategoryId: _selectedCategoryId!,
          measurementUnitId: _measurementUnitId!,
          name: name,
          outputQuantity: int.tryParse(_outputCtl.text.trim()) ?? 0,
          ingredients: ingredients,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.recipeSaveSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        _showError(s.recipeErrorSnackbar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final batchAsync = ref.watch(recipeBatchUnitsProvider);

    ref.listen<AsyncValue<List<MeasurementUnitModel>>>(
      recipeBatchUnitsProvider,
      (prev, next) {
        next.whenData((units) {
          if (units.isEmpty || _measurementUnitId != null) return;
          setState(() => _measurementUnitId = units.first.id);
        });
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(s.recipeCreateTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _ProgressBar(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            labels: [s.recipeStepProduct, s.recipeStepBatch, s.recipeStepIngredients],
          ),
          Expanded(
            child: ClipRect(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Product(context, s, cs),
                  _buildStep2Batch(context, s, cs, batchAsync),
                  _buildStep3Ingredients(context, s, cs),
                ],
              ),
            ),
          ),
          // 1-qadamda avto-advance ishlaydi — pastki panel butunlay yashiriladi.
          if (_currentStep > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        child: Text(s.recipeBack),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _currentStep == _totalSteps - 1
                          ? ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(s.actionSave),
                            )
                          : ElevatedButton(
                              onPressed: _nextStep,
                              child: Text(s.next),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1Product(BuildContext context, S s, ColorScheme cs) {
    final categories = ref.watch(breadCategoryProvider).items;
    final recipes = ref.watch(recipeProvider).items;
    final usedCategoryIds = {
      for (final r in recipes) r.breadCategory?.id,
    }..remove(null);
    final bottomPad = 20 + MediaQuery.viewInsetsOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
      children: [
        Text(
          s.recipeSelectProductTitle,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.recipeSelectProductSubtitle,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline,
                    size: 32, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(
                  s.productCategoriesEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...categories.map((cat) {
            final hasRecipe = usedCategoryIds.contains(cat.id);
            final isSelected = _selectedCategoryId == cat.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasRecipe ? null : () => _onCategoryTap(cat.id),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasRecipe
                          ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                          : isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasRecipe
                            ? cs.outline.withValues(alpha: 0.08)
                            : isSelected
                                ? AppColors.primary
                                : cs.outline.withValues(alpha: 0.12),
                        width: isSelected && !hasRecipe ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: hasRecipe
                                ? cs.surfaceContainerHighest
                                : isSelected
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasRecipe
                                ? Icons.check_circle_outline_rounded
                                : Icons.inventory_2_outlined,
                            color: hasRecipe
                                ? AppColors.success.withValues(alpha: 0.6)
                                : isSelected
                                    ? AppColors.primary
                                    : cs.onSurface.withValues(alpha: 0.4),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: TextStyle(
                                  color: hasRecipe
                                      ? cs.onSurface.withValues(alpha: 0.4)
                                      : cs.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                hasRecipe
                                    ? s.recipeAlreadyExists
                                    : '${_fmtNum(context, cat.sellingPrice)} ${cat.priceSuffix(s.currency)}',
                                style: TextStyle(
                                  color: hasRecipe
                                      ? AppColors.success.withValues(alpha: 0.7)
                                      : cs.onSurface.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontWeight: hasRecipe
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasRecipe)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success.withValues(alpha: 0.5),
                            size: 22,
                          )
                        else
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : cs.outline.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep2Batch(
    BuildContext context,
    S s,
    ColorScheme cs,
    AsyncValue<List<MeasurementUnitModel>> batchAsync,
  ) {
    final bottomPad = 20 + MediaQuery.viewInsetsOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 24, 0, bottomPad),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            s.recipeBatchCarouselTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            s.recipeBatchCarouselSubtitle,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _BatchUnitCarousel(
          async: batchAsync,
          selectedId: _measurementUnitId,
          onSelect: (id) => setState(() => _measurementUnitId = id),
          localizedName: _batchUnitDisplayName,
          emptyText: s.recipeValidationBatch,
          errorText: s.snackbarErrorGeneric,
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _OutputQuantityField(
            controller: _outputCtl,
            focusNode: _outputFocusNode,
            suffix: s.pcs,
            hint: s.recipeOutputHint,
            label: _resolveOutputLabel(s, batchAsync),
          ),
        ),
      ],
    );
  }

  /// Tanlangan partiya birligiga mos dinamik sarlavha.
  /// Agar birlik hali tanlanmagan/yuklanmagan bo'lsa, statik `recipeOutputLabel`
  /// fallback sifatida qaytariladi.
  String _resolveOutputLabel(
    S s,
    AsyncValue<List<MeasurementUnitModel>> async,
  ) {
    final units = switch (async) {
      AsyncData<List<MeasurementUnitModel>>(:final value) => value,
      _ => const <MeasurementUnitModel>[],
    };
    final selected = _selectedBatchUnit(units);
    if (selected == null) return s.recipeOutputLabel;
    return s.recipeOutputLabelDynamic(_batchUnitInlineName(selected));
  }

  Widget _buildStep3Ingredients(BuildContext context, S s, ColorScheme cs) {
    final allIngredients = ref.watch(ingredientProvider).items;
    final bottomPad =
        20 + MediaQuery.viewInsetsOf(context).bottom;
    final batchAsync = ref.watch(recipeBatchUnitsProvider);
    final units = switch (batchAsync) {
      AsyncData<List<MeasurementUnitModel>>(:final value) => value,
      _ => const <MeasurementUnitModel>[],
    };
    final selectedUnit = _selectedBatchUnit(units);
    final inlineName =
        selectedUnit != null ? _batchUnitInlineName(selectedUnit) : null;
    final title = inlineName != null
        ? s.recipeIngredientsSectionTitleDynamic(inlineName)
        : s.recipeIngredientsSectionTitle;
    final subtitle = inlineName != null
        ? s.recipeIngredientsSectionSubtitleDynamic(inlineName)
        : s.recipeIngredientsSectionSubtitle;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
      children: [
        Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        if (_ingredientEntries.isEmpty && allIngredients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline,
                    size: 32, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(
                  s.ingredientsEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        if (_ingredientEntries.isEmpty && allIngredients.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 32, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(
                  s.recipeValidationIngredients,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(_ingredientEntries.length, (i) {
          final entry = _ingredientEntries[i];
          final usedIds = _ingredientEntries
              .where((e) => e != entry && e.ingredientId != null)
              .map((e) => e.ingredientId!)
              .toSet();
          final availableIngredients = allIngredients
              .where((ing) =>
                  !usedIds.contains(ing.id) || ing.id == entry.ingredientId)
              .toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: entry.ingredientId,
                      decoration: InputDecoration(
                        hintText: s.recipeIngredientSelectHint,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      isExpanded: true,
                      items: availableIngredients
                          .map((ing) => DropdownMenuItem(
                                value: ing.id,
                                child: Text(ing.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => entry.ingredientId = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Builder(
                      builder: (fieldContext) {
                        final suffix =
                            _quantitySuffix(entry, allIngredients);
                        return TextFormField(
                          controller: entry.quantityController,
                          decoration: InputDecoration(
                            hintText: '0.0',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: suffix == null
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      right: 12,
                                      left: 4,
                                    ),
                                    child: Text(
                                      suffix,
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                            suffixIconConstraints: const BoxConstraints(
                              
                            ),
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.error),
                    onPressed: () =>
                        setState(() => _ingredientEntries.removeAt(i)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        if (allIngredients.isNotEmpty)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final saved = await showIngredientFormSheet(context);
                    if (saved && mounted) setState(() {});
                  },
                  icon: Icon(Icons.auto_awesome_rounded, size: 18, color: cs.primary),
                  label: Text(
                    s.recipeCreateNewIngredientShort,
                    style: TextStyle(color: cs.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: BorderSide(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    s.recipeAddIngredient,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const _ProgressBar({
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (i) {
              if (i.isOdd) {
                final stepBefore = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: stepBefore < currentStep
                          ? AppColors.primary
                          : cs.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final step = i ~/ 2;
              final isCompleted = step < currentStep;
              final isCurrent = step == currentStep;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : isCurrent
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: isCurrent
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 16)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: isCurrent
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (i) {
              final isCurrent = i == currentStep;
              final isCompleted = i < currentStep;
              return SizedBox(
                width: 90,
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCurrent || isCompleted
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _IngredientEntry {
  String? ingredientId;
  final TextEditingController quantityController;

  _IngredientEntry({required this.quantityController});
}

/// Partiya birliklari uchun gorizontal (yonga scroll qilinadigan) karusel.
///
/// Kartalar ko'tarilgan dizayn bilan: ikonka + nom, tanlanganida `primary`
/// rang chegara va yoritilgan orqa fon bilan ajralib turadi.
class _BatchUnitCarousel extends StatelessWidget {
  const _BatchUnitCarousel({
    required this.async,
    required this.selectedId,
    required this.onSelect,
    required this.localizedName,
    required this.emptyText,
    required this.errorText,
  });

  final AsyncValue<List<MeasurementUnitModel>> async;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final String Function(MeasurementUnitModel unit) localizedName;
  final String emptyText;
  final String errorText;

  static const double _cardWidth = 112;
  static const double _cardHeight = 108;
  static const EdgeInsets _listPadding = EdgeInsets.symmetric(horizontal: 20);

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const SizedBox(
        height: _cardHeight,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorText,
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (units) {
        if (units.isEmpty) {
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }
        return SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: _listPadding,
            itemCount: units.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final u = units[i];
              return _BatchUnitCard(
                icon: u.icon,
                label: localizedName(u),
                isActive: u.id == selectedId,
                onTap: () => onSelect(u.id),
                width: _cardWidth,
              );
            },
          ),
        );
      },
    );
  }
}

/// Bitta partiya birligi kartasi (karusel elementi).
class _BatchUnitCard extends StatelessWidget {
  const _BatchUnitCard({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.width,
  });

  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : cs.outline.withValues(alpha: 0.1),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : cs.onSurface,
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mahsulot chiqimini kiritadigan raqamli input.
///
/// `label` tashqaridan beriladi va tanlangan partiya birligiga qarab
/// dinamik yangilanadi (masalan "1 blokdan qancha mahsulot chiqadi?").
class _OutputQuantityField extends StatelessWidget {
  const _OutputQuantityField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.suffix,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
}
