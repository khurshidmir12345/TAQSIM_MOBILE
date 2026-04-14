import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../domain/models/bread_category_model.dart';
import '../../domain/models/ingredient_model.dart';
import '../../domain/providers/setup_provider.dart';

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

  String? _quantitySuffix(
    _IngredientEntry entry,
    List<IngredientModel> allIngredients,
  ) {
    final id = entry.ingredientId;
    if (id == null) return null;
    for (final ing in allIngredients) {
      if (ing.id == id) return ing.displayUnitLine;
    }
    return null;
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
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        child: Text(s.recipeBack),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
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
                                        strokeWidth: 2, color: Colors.white),
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
                  onTap: hasRecipe
                      ? null
                      : () => setState(() => _selectedCategoryId = cat.id),
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
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
      children: [
        Text(
          s.recipeOutputSectionTitle,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.recipeOutputSectionHelper,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _outputCtl,
          focusNode: _outputFocusNode,
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            labelText: s.recipeOutputLabel,
            hintText: s.recipeOutputHint,
            suffixText: s.pcs,
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
        ),
        const SizedBox(height: 28),
        Text(
          s.recipeBatchCarouselTitle,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.recipeBatchCarouselSubtitle,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        batchAsync.when(
          data: (units) {
            if (units.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.recipeValidationBatch,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(units.length, (i) {
                final u = units[i];
                final lang = Localizations.localeOf(context).languageCode;
                final name = u.localizedName(lang);
                final isActive = _measurementUnitId == u.id;
                final cardWidth =
                    (MediaQuery.sizeOf(context).width - 40 - 20) / 3;

                return GestureDetector(
                  onTap: () => setState(() => _measurementUnitId = u.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: cardWidth,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(u.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(
                          name.isNotEmpty ? name : u.batchDisplayLabel,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.primary
                                : cs.onSurface,
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              s.snackbarErrorGeneric,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Ingredients(BuildContext context, S s, ColorScheme cs) {
    final allIngredients = ref.watch(ingredientProvider).items;
    final bottomPad =
        20 + MediaQuery.viewInsetsOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
      children: [
        Text(
          s.recipeIngredientsSectionTitle,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.recipeIngredientsSectionSubtitle,
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
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    child: TextFormField(
                      controller: entry.quantityController,
                      decoration: InputDecoration(
                        hintText: '0.0',
                        suffixText: _quantitySuffix(entry, allIngredients),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
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
          OutlinedButton.icon(
            onPressed: _addIngredient,
            icon: const Icon(Icons.add, size: 18),
            label: Text(s.recipeAddIngredient),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
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
