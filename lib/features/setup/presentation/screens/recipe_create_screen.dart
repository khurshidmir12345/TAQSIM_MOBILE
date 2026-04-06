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
  final _pageController = PageController(viewportFraction: 0.88);
  final _batchCarouselController = PageController(viewportFraction: 0.82);
  int _currentStep = 0;
  static const _totalSteps = 3;

  String? _selectedCategoryId;
  String? _measurementUnitId;
  int _batchPageIndex = 0;

  final _outputCtl = TextEditingController();
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
    _batchCarouselController.dispose();
    _outputCtl.dispose();
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

  String _localeCode() {
    final l = Localizations.localeOf(context);
    return l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
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
          if (units.isEmpty) return;
          final i = _batchPageIndex.clamp(0, units.length - 1);
          final id = units[i].id;
          if (_measurementUnitId != id) {
            setState(() => _measurementUnitId = id);
          }
        });
      },
    );

    return Scaffold(
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
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Product(context, s, cs),
                _buildStep2Batch(s, cs, batchAsync),
                _buildStep3Ingredients(s, cs),
              ],
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
            final isSelected = _selectedCategoryId == cat.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : cs.outline.withValues(alpha: 0.12),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: isSelected
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
                                  color: cs.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_fmtNum(context, cat.sellingPrice)} ${cat.priceSuffix(s.currency)}',
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
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
    S s,
    ColorScheme cs,
    AsyncValue<List<MeasurementUnitModel>> batchAsync,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        Text(
          s.recipeBatchCarouselTitle,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.recipeBatchCarouselSubtitle,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        batchAsync.when(
          data: (units) {
            if (units.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.recipeValidationBatch,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _batchCarouselController,
                    itemCount: units.length,
                    onPageChanged: (i) {
                      setState(() {
                        _batchPageIndex = i;
                        _measurementUnitId = units[i].id;
                      });
                    },
                    itemBuilder: (context, i) {
                      final u = units[i];
                      final loc = _localeCode();
                      final lang = Localizations.localeOf(context).languageCode;
                      final fullName = u.localizedName(lang);
                      final ex = u.localizedExample(loc);
                      final isActive = i == _batchPageIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : cs.outline.withValues(alpha: 0.1),
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.icon,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                u.code,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if (fullName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  fullName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.72),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                              if (ex != null && ex.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  ex,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.45),
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(units.length, (i) {
                    final on = i == _batchPageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: on ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: on ? AppColors.primary : cs.outline.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
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
        const SizedBox(height: 28),
        TextFormField(
          controller: _outputCtl,
          decoration: InputDecoration(
            labelText: s.recipeOutputLabel,
            hintText: s.recipeOutputHint,
            suffixText: s.pcs,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep3Ingredients(S s, ColorScheme cs) {
    final allIngredients = ref.watch(ingredientProvider).items;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                      value: entry.ingredientId,
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
