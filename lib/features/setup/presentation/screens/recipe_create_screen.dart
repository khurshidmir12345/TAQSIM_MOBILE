import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../domain/models/bread_category_model.dart';
import '../../domain/models/ingredient_model.dart';
import '../../domain/providers/setup_provider.dart';
import '../widgets/custom_batch_unit_sheet.dart';
import '../widgets/ingredient_form_sheet.dart';

/// Hisob turi: bir dona mahsulot uchun yoki to'plam (qop, blok, qozon...) uchun.
enum _RecipeMode { single, set }

/// "Bir dona" rejimida ishlatiladigan tizim partiya birligi kodi.
const String _kPieceUnitCode = 'dona_batch';

class RecipeCreateScreen extends ConsumerStatefulWidget {
  const RecipeCreateScreen({super.key});

  @override
  ConsumerState<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 3;

  String? _selectedCategoryId;
  _RecipeMode? _mode;
  String? _measurementUnitId;

  final _outputCtl = TextEditingController();
  final _outputFocusNode = FocusNode();
  final List<_IngredientEntry> _ingredientEntries = [];

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
    for (final e in _ingredientEntries) {
      e.quantityController.dispose();
      e.focusNode.dispose();
    }
    super.dispose();
  }

  // ─── Yordamchilar ──────────────────────────────────────────────────────

  List<MeasurementUnitModel> _units() {
    return switch (ref.read(recipeBatchUnitsProvider)) {
      AsyncData<List<MeasurementUnitModel>>(:final value) => value,
      _ => const <MeasurementUnitModel>[],
    };
  }

  MeasurementUnitModel? _pieceUnit(List<MeasurementUnitModel> units) {
    for (final u in units) {
      if (u.code == _kPieceUnitCode) return u;
    }
    return null;
  }

  /// Foydalanuvchi tanlagan til kodi (uz, uz_CYRL, ru, kk, ky, tr).
  String _currentLocaleCode() {
    final async = ref.read(localeProvider);
    return (async.value ?? AppLocale.uz).code;
  }

  /// Partiya birligining lokallashgan qisqa nomi ("Blok", "Qop", "KG", ...).
  String _batchUnitDisplayName(MeasurementUnitModel u) =>
      u.batchShortLabel(_currentLocaleCode());

  /// Jumla ichida ishlatiladigan kichik harfli variant ("1 blokdan ...").
  String _batchUnitInlineName(MeasurementUnitModel u) =>
      _batchUnitDisplayName(u).toLowerCase();

  MeasurementUnitModel? _selectedBatchUnit(List<MeasurementUnitModel> units) {
    if (_measurementUnitId == null) return null;
    for (final u in units) {
      if (u.id == _measurementUnitId) return u;
    }
    return null;
  }

  /// `kg` → `Kg`, `ml` → `Ml`.
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  // ─── Qadamlar ──────────────────────────────────────────────────────────

  void _goTo(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextStep() {
    final s = S.of(context);
    if (_currentStep == 0 && _selectedCategoryId == null) {
      _showError(s.recipeValidationSelectProduct);
      return;
    }
    if (_currentStep == 1) {
      if (_mode == null) {
        _showError(s.recipeModeQuestion);
        return;
      }
      if (_measurementUnitId == null) {
        _showError(s.recipeValidationBatch);
        return;
      }
      final output = int.tryParse(_outputCtl.text.trim()) ?? 0;
      if (output <= 0) {
        _showError(s.recipeValidationOutput);
        _outputFocusNode.requestFocus();
        return;
      }
    }
    if (_currentStep < _totalSteps - 1) {
      FocusScope.of(context).unfocus();
      _goTo(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      _goTo(_currentStep - 1);
    }
  }

  /// 1-qadam: kartaga bosilganda qisqa pauza, so'ng avtomatik 2-qadam.
  void _onCategoryTap(String categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _currentStep != 0) return;
      _nextStep();
    });
  }

  /// 2-qadam: "Bir dona" → «Dona» birligi, chiqim 1, darrov tarkibga.
  /// "To'plam" → karusel va chiqim maydoni ochiladi.
  void _onModeTap(_RecipeMode mode) {
    final s = S.of(context);
    final units = _units();
    final piece = _pieceUnit(units);

    if (mode == _RecipeMode.single) {
      if (piece == null) {
        _showError(s.recipeSingleUnitMissing);
        return;
      }
      setState(() {
        _mode = mode;
        _measurementUnitId = piece.id;
        _outputCtl.text = '1';
      });
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || _currentStep != 1) return;
        _nextStep();
      });
      return;
    }

    setState(() {
      final wasSingle = _mode == _RecipeMode.single;
      _mode = mode;
      if (wasSingle) _outputCtl.clear();
      // «Dona» to'plam uchun mantiqsiz — birinchi boshqa birlikni taklif qilamiz.
      if (_measurementUnitId == null || _measurementUnitId == piece?.id) {
        MeasurementUnitModel? first;
        for (final u in units) {
          if (u.id != piece?.id) {
            first = u;
            break;
          }
        }
        _measurementUnitId = first?.id ?? _measurementUnitId;
      }
    });
  }

  void _onBatchUnitSelect(String id) {
    setState(() => _measurementUnitId = id);
    _outputFocusNode.requestFocus();
  }

  Future<void> _onAddCustomUnit() async {
    final s = S.of(context);
    FocusScope.of(context).unfocus();
    final unit = await showCustomBatchUnitSheet(context);
    if (unit == null || !mounted) return;
    setState(() => _measurementUnitId = unit.id);
    _showInfo(s.recipeCustomUnitSaved);
    _outputFocusNode.requestFocus();
  }

  Future<void> _onDeleteCustomUnit(MeasurementUnitModel unit) async {
    final s = S.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: s.recipeCustomUnitDeleteTitle,
      message: s.recipeCustomUnitDeleteBody(_batchUnitDisplayName(unit)),
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(recipeBatchUnitsProvider.notifier).removeCustom(unit.id);
      if (!mounted) return;
      if (_measurementUnitId == unit.id) {
        setState(() => _measurementUnitId = null);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e is ApiException ? e.message : s.snackbarErrorGeneric);
    }
  }

  // ─── Tarkib ────────────────────────────────────────────────────────────

  /// Karuseldan xom ashyo tanlash → listga qator qo'shiladi va fokus beriladi.
  void _onIngredientChipTap(IngredientModel ing) {
    final s = S.of(context);
    if (_ingredientEntries.any((e) => e.ingredientId == ing.id)) {
      _showError(s.recipeValidationDuplicateIngredient);
      return;
    }
    final entry = _IngredientEntry(
      ingredientId: ing.id,
      quantityController: TextEditingController(),
      focusNode: FocusNode(),
    );
    setState(() => _ingredientEntries.add(entry));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) entry.focusNode.requestFocus();
    });
  }

  void _removeEntry(int index) {
    final entry = _ingredientEntries[index];
    setState(() => _ingredientEntries.removeAt(index));
    entry.quantityController.dispose();
    entry.focusNode.dispose();
  }

  double _entryQty(_IngredientEntry e) =>
      parseDecimalInput(e.quantityController.text) ?? 0;

  Future<void> _save() async {
    final s = S.of(context);

    if (_ingredientEntries.isEmpty) {
      _showError(s.recipeValidationIngredients);
      return;
    }

    // Miqdori kiritilmagan qator bo'lsa — jimgina tashlab yubormaymiz,
    // foydalanuvchi ko'pincha bitta xom ashyoni bosib "Saqlash"ni ezadi.
    for (final e in _ingredientEntries) {
      if (_entryQty(e) <= 0) {
        _showError(s.recipeValidationQuantityMissing);
        e.focusNode.requestFocus();
        return;
      }
    }

    final ids = _ingredientEntries.map((e) => e.ingredientId).toSet();
    if (ids.length != _ingredientEntries.length) {
      _showError(s.recipeValidationDuplicateIngredient);
      return;
    }

    if (_measurementUnitId == null) {
      _showError(s.recipeValidationBatch);
      return;
    }

    // Faqat bitta xom ashyo — odatda xato. Tasdiq so'raymiz.
    if (_ingredientEntries.length == 1) {
      final proceed = await _confirmSingleIngredient(s);
      if (!proceed || !mounted) return;
    }

    setState(() => _isSaving = true);

    final categories = ref.read(breadCategoryProvider).items;
    String name = '';
    for (final c in categories) {
      if (c.id == _selectedCategoryId) {
        name = c.name;
        break;
      }
    }

    final ingredients = _ingredientEntries
        .map(
          (e) => {'ingredient_id': e.ingredientId!, 'quantity': _entryQty(e)},
        )
        .toList();

    final ok = await ref
        .read(recipeProvider.notifier)
        .create(
          breadCategoryId: _selectedCategoryId!,
          measurementUnitId: _measurementUnitId!,
          name: name,
          outputQuantity: int.tryParse(_outputCtl.text.trim()) ?? 0,
          ingredients: ingredients,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      _showInfo(s.recipeSaveSuccess);
      context.pop();
    } else {
      _showError(s.recipeErrorSnackbar);
    }
  }

  Future<bool> _confirmSingleIngredient(S s) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.recipeSingleIngredientTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          s.recipeSingleIngredientBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: cs.onSurfaceVariant,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.recipeSingleIngredientAddMore),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.recipeSingleIngredientSaveAnyway),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final batchAsync = ref.watch(recipeBatchUnitsProvider);

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prevStep();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(
              _currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
            ),
            onPressed: _isSaving
                ? null
                : (_currentStep > 0 ? _prevStep : () => context.pop()),
          ),
          title: Text(
            s.recipeCreateTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            _StepDots(current: _currentStep, total: _totalSteps),
            const SizedBox(width: 10),
            if (_currentStep == 1)
              TextButton(
                onPressed: _nextStep,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.next,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            if (_currentStep == 2)
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.actionSave,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
            const SizedBox(width: 12),
          ],
        ),
        body: ClipRect(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1Product(context, s, cs),
              _buildStep2Mode(context, s, cs, batchAsync),
              _buildStep3Ingredients(context, s, cs),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1-qadam: mahsulot ─────────────────────────────────────────────────

  Widget _buildStep1Product(BuildContext context, S s, ColorScheme cs) {
    final categories = ref.watch(breadCategoryProvider).items;
    final recipes = ref.watch(recipeProvider).items;
    final usedCategoryIds = {for (final r in recipes) r.breadCategory?.id}
      ..remove(null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _StepHeader(
          title: s.recipeSelectProductTitle,
          subtitle: s.recipeSelectProductSubtitle,
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty)
          _InfoBox(text: s.productCategoriesEmptySubtitle)
        else
          ...categories.map((cat) {
            final hasRecipe = usedCategoryIds.contains(cat.id);
            final isSelected = _selectedCategoryId == cat.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ProductTile(
                category: cat,
                hasRecipe: hasRecipe,
                isSelected: isSelected,
                priceLine:
                    '${_fmtNum(context, cat.sellingPrice)} ${cat.priceSuffix(s.currency)}',
                existsLabel: s.recipeAlreadyExists,
                onTap: hasRecipe ? null : () => _onCategoryTap(cat.id),
              ),
            );
          }),
      ],
    );
  }

  // ─── 2-qadam: hisob turi + to'plam ─────────────────────────────────────

  Widget _buildStep2Mode(
    BuildContext context,
    S s,
    ColorScheme cs,
    AsyncValue<List<MeasurementUnitModel>> batchAsync,
  ) {
    final bottomPad = 24 + MediaQuery.viewInsetsOf(context).bottom;
    final isSet = _mode == _RecipeMode.set;

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _StepHeader(title: s.recipeModeQuestion),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ModeCard(
                  icon: Icons.looks_one_rounded,
                  title: s.recipeModeSingleTitle,
                  subtitle: s.recipeModeSingleSubtitle,
                  selected: _mode == _RecipeMode.single,
                  onTap: () => _onModeTap(_RecipeMode.single),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  icon: Icons.grid_view_rounded,
                  title: s.recipeModeSetTitle,
                  subtitle: s.recipeModeSetSubtitle,
                  selected: isSet,
                  onTap: () => _onModeTap(_RecipeMode.set),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !isSet
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        s.recipeSetPickTitle,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BatchUnitCarousel(
                      async: batchAsync,
                      selectedId: _measurementUnitId,
                      hiddenCode: _kPieceUnitCode,
                      onSelect: _onBatchUnitSelect,
                      onAddCustom: _onAddCustomUnit,
                      onDeleteCustom: _onDeleteCustomUnit,
                      localizedName: _batchUnitDisplayName,
                      addLabel: s.recipeCustomUnitAdd,
                      emptyText: s.recipeValidationBatch,
                      errorText: s.snackbarErrorGeneric,
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _OutputQuantityField(
                        controller: _outputCtl,
                        focusNode: _outputFocusNode,
                        suffix: s.pcs,
                        hint: s.recipeOutputHint,
                        label: _resolveOutputLabel(s, batchAsync),
                        onSubmitted: _nextStep,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Tanlangan partiya birligiga mos dinamik sarlavha.
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

  // ─── 3-qadam: tarkib ───────────────────────────────────────────────────

  Widget _buildStep3Ingredients(BuildContext context, S s, ColorScheme cs) {
    final allIngredients = ref.watch(ingredientProvider).items;
    final bottomPad = 24 + MediaQuery.viewInsetsOf(context).bottom;
    final units = switch (ref.watch(recipeBatchUnitsProvider)) {
      AsyncData<List<MeasurementUnitModel>>(:final value) => value,
      _ => const <MeasurementUnitModel>[],
    };
    final selectedUnit = _selectedBatchUnit(units);
    final inlineName = selectedUnit != null
        ? _batchUnitInlineName(selectedUnit)
        : null;
    final title = inlineName != null
        ? s.recipeIngredientsSectionTitleDynamic(inlineName)
        : s.recipeIngredientsSectionTitle;

    final addedIds = _ingredientEntries
        .map((e) => e.ingredientId)
        .whereType<String>()
        .toSet();
    final availableIngredients = allIngredients
        .where((ing) => !addedIds.contains(ing.id))
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _StepHeader(
            title: title,
            subtitle: s.recipeIngredientTapHint,
            subtitleIcon: Icons.touch_app_rounded,
          ),
        ),
        const SizedBox(height: 10),
        _IngredientChipCarousel(
          available: availableIngredients,
          onTap: _onIngredientChipTap,
          onCreateNew: () async {
            final saved = await showIngredientFormSheet(context);
            if (saved && mounted) setState(() {});
          },
          newLabel: s.recipeCreateNewIngredientShort,
        ),
        const SizedBox(height: 12),
        if (_ingredientEntries.isEmpty && allIngredients.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _InfoBox(text: s.ingredientsEmptySubtitle),
          )
        else if (_ingredientEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _InfoBox(
              text: s.recipeValidationIngredients,
              icon: Icons.arrow_upward_rounded,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(_ingredientEntries.length, (i) {
                final entry = _ingredientEntries[i];
                final ing = allIngredients.firstWhere(
                  (x) => x.id == entry.ingredientId,
                  orElse: () => allIngredients.first,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IngredientEntryTile(
                    name: ing.name,
                    controller: entry.quantityController,
                    focusNode: entry.focusNode,
                    unitCode: _capitalizeUnitCode(ing.displayUnitLine),
                    onRemove: () => _removeEntry(i),
                    onSubmitted: () => FocusScope.of(context).unfocus(),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ─── Kichik widgetlar ────────────────────────────────────────────────────

/// AppBar'dagi juda kichik qadam ko'rsatkichi: nuqtalar + "2/3".
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: i == current ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i <= current
                  ? AppColors.primary
                  : cs.onSurface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          '${current + 1}/$total',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.55),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Ixcham qadam sarlavhasi: bir qatorli title + kichik izoh.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, this.subtitle, this.subtitleIcon});

  final String title;
  final String? subtitle;
  final IconData? subtitleIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (subtitleIcon != null) ...[
                Icon(
                  subtitleIcon,
                  size: 14,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text, this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.category,
    required this.hasRecipe,
    required this.isSelected,
    required this.priceLine,
    required this.existsLabel,
    required this.onTap,
  });

  final BreadCategoryModel category;
  final bool hasRecipe;
  final bool isSelected;
  final String priceLine;
  final String existsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: hasRecipe
                ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
                : isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasRecipe
                  ? cs.outline.withValues(alpha: 0.08)
                  : isSelected
                  ? AppColors.primary
                  : cs.outline.withValues(alpha: 0.14),
              width: isSelected && !hasRecipe ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected && !hasRecipe
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(11),
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasRecipe
                            ? cs.onSurface.withValues(alpha: 0.4)
                            : cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasRecipe ? existsLabel : priceLine,
                      style: TextStyle(
                        color: hasRecipe
                            ? AppColors.success.withValues(alpha: 0.7)
                            : cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 12.5,
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
                  size: 20,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : cs.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hisob turi kartasi: "Bir dona" / "To'plam".
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : cs.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : cs.outline.withValues(alpha: 0.12),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : cs.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? AppColors.primary : cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientEntry {
  String? ingredientId;
  final TextEditingController quantityController;
  final FocusNode focusNode;

  _IngredientEntry({
    this.ingredientId,
    required this.quantityController,
    required this.focusNode,
  });
}

/// Partiya birliklari karuseli. Oxirida "+ O'zim" kartasi — foydalanuvchi
/// o'z birligini (nom + stiker) qo'shadi. Maxsus birlikni uzoq bosib
/// o'chirish mumkin.
class _BatchUnitCarousel extends StatelessWidget {
  const _BatchUnitCarousel({
    required this.async,
    required this.selectedId,
    required this.hiddenCode,
    required this.onSelect,
    required this.onAddCustom,
    required this.onDeleteCustom,
    required this.localizedName,
    required this.addLabel,
    required this.emptyText,
    required this.errorText,
  });

  final AsyncValue<List<MeasurementUnitModel>> async;
  final String? selectedId;

  /// Karuselda ko'rsatilmaydigan kod («Dona» — bir dona rejimi uchun).
  final String hiddenCode;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCustom;
  final ValueChanged<MeasurementUnitModel> onDeleteCustom;
  final String Function(MeasurementUnitModel unit) localizedName;
  final String addLabel;
  final String emptyText;
  final String errorText;

  static const double _cardWidth = 92;
  static const double _cardHeight = 94;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const SizedBox(
        height: _cardHeight,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(errorText, style: const TextStyle(color: AppColors.error)),
      ),
      data: (all) {
        final units = all.where((u) => u.code != hiddenCode).toList();
        if (units.isEmpty) {
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          );
        }
        return SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: units.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == units.length) {
                return _AddUnitCard(
                  label: addLabel,
                  onTap: onAddCustom,
                  width: _cardWidth,
                );
              }
              final u = units[i];
              return _BatchUnitCard(
                icon: u.icon,
                label: localizedName(u),
                isActive: u.id == selectedId,
                isCustom: u.isCustom,
                onTap: () => onSelect(u.id),
                onLongPress: u.isCustom ? () => onDeleteCustom(u) : null,
                width: _cardWidth,
              );
            },
          ),
        );
      },
    );
  }
}

class _BatchUnitCard extends StatelessWidget {
  const _BatchUnitCard({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCustom,
    required this.onTap,
    required this.onLongPress,
    required this.width,
  });

  final String icon;
  final String label;
  final bool isActive;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : cs.outline.withValues(alpha: 0.1),
              width: isActive ? 1.8 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 22, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? AppColors.primary : cs.onSurface,
                          fontSize: 11.5,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCustom)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.person_rounded,
                    size: 12,
                    color: (isActive ? AppColors.primary : cs.onSurface)
                        .withValues(alpha: 0.45),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karusel oxiridagi "+ O'zim" — chiziqli chegara, yaratish action'i.
class _AddUnitCard extends StatelessWidget {
  const _AddUnitCard({
    required this.label,
    required this.onTap,
    required this.width,
  });

  final String label;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mahsulot chiqimini kiritadigan raqamli input.
class _OutputQuantityField extends StatelessWidget {
  const _OutputQuantityField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String suffix;
  final VoidCallback onSubmitted;

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
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmitted(),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 3-qadam — xom ashyo karuseli.
///
/// Birinchi element — "+ Yangi" (yangi xom ashyo yaratish), keyin mavjud
/// xom ashyolar; har biri "+" belgisi bilan — bosilsa ro'yxatga qo'shiladi.
class _IngredientChipCarousel extends StatelessWidget {
  const _IngredientChipCarousel({
    required this.available,
    required this.onTap,
    required this.onCreateNew,
    required this.newLabel,
  });

  final List<IngredientModel> available;
  final ValueChanged<IngredientModel> onTap;
  final VoidCallback onCreateNew;
  final String newLabel;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: available.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _NewIngredientChip(label: newLabel, onTap: onCreateNew);
          }
          final ing = available[i - 1];
          return _IngredientChip(label: ing.name, onTap: () => onTap(ing));
        },
      ),
    );
  }
}

class _NewIngredientChip extends StatelessWidget {
  const _NewIngredientChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mavjud xom ashyo chipi — "+" belgisi bosib qo'shilishini bildiradi.
class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Retseptga qo'shilgan xom ashyo qatori — inline editable miqdor input.
class _IngredientEntryTile extends StatelessWidget {
  const _IngredientEntryTile({
    required this.name,
    required this.controller,
    required this.focusNode,
    required this.unitCode,
    required this.onRemove,
    required this.onSubmitted,
  });

  final String name;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String unitCode;
  final VoidCallback onRemove;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 2, 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [DecimalTextInputFormatter()],
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                isDense: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: cs.outline.withValues(alpha: 0.18),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: cs.outline.withValues(alpha: 0.18),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.6,
                  ),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10, left: 4),
                  child: Text(
                    unitCode,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(),
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          ),
        ],
      ),
    );
  }
}
