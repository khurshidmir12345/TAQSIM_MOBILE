import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../domain/models/ingredient_model.dart';
import '../../domain/models/recipe_model.dart';
import '../../domain/providers/setup_provider.dart';
import '../widgets/ingredient_form_sheet.dart';
import '../widgets/recipe_card.dart';
import '../widgets/recipe_ingredient_widgets.dart';

/// Mavjud hisoblashni tahrirlash: xom ashyo qo'shish/olib tashlash, miqdor va
/// chiqimni o'zgartirish. Tannarx jonli ko'rsatiladi, saqlangach backend
/// qayta hisoblaydi.
class RecipeEditScreen extends ConsumerStatefulWidget {
  const RecipeEditScreen({super.key, required this.recipe});

  final RecipeModel recipe;

  @override
  ConsumerState<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends ConsumerState<RecipeEditScreen> {
  late final TextEditingController _outputCtl = TextEditingController(
    text: '${widget.recipe.outputQuantity}',
  );
  final List<RecipeIngredientEntry> _entries = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final ri in widget.recipe.ingredients) {
      _entries.add(
        RecipeIngredientEntry(
          ingredientId: ri.ingredientId,
          quantityController: TextEditingController(
            text: editableQuantity(ri.quantity),
          ),
          focusNode: FocusNode(),
        ),
      );
    }
    Future.microtask(() => ref.read(ingredientProvider.notifier).load());
  }

  @override
  void dispose() {
    _outputCtl.dispose();
    for (final e in _entries) {
      e.quantityController.dispose();
      e.focusNode.dispose();
    }
    super.dispose();
  }

  String _unitInlineName() {
    final async = ref.read(localeProvider);
    final code = (async.value ?? AppLocale.uz).code;
    return widget.recipe.measurementUnit?.batchShortLabel(code).toLowerCase() ??
        '';
  }

  String _capitalizeUnitCode(String code) {
    if (code.isEmpty) return code;
    return code.substring(0, 1).toUpperCase() +
        (code.length > 1 ? code.substring(1).toLowerCase() : '');
  }

  double _qty(RecipeIngredientEntry e) =>
      parseDecimalInput(e.quantityController.text) ?? 0;

  void _showSnack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _onChipTap(IngredientModel ing) {
    final s = S.of(context);
    if (_entries.any((e) => e.ingredientId == ing.id)) {
      _showSnack(s.recipeValidationDuplicateIngredient);
      return;
    }
    final entry = RecipeIngredientEntry(
      ingredientId: ing.id,
      quantityController: TextEditingController(),
      focusNode: FocusNode(),
    );
    setState(() => _entries.add(entry));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) entry.focusNode.requestFocus();
    });
  }

  void _removeEntry(int i) {
    final e = _entries[i];
    setState(() => _entries.removeAt(i));
    e.quantityController.dispose();
    e.focusNode.dispose();
  }

  /// Jonli tannarx: miqdor × xom ashyoning joriy narxi.
  (double total, double perUnit) _preview(List<IngredientModel> all) {
    var total = 0.0;
    for (final e in _entries) {
      IngredientModel? ing;
      for (final x in all) {
        if (x.id == e.ingredientId) {
          ing = x;
          break;
        }
      }
      if (ing == null) continue;
      total += _qty(e) * (double.tryParse(ing.pricePerUnit) ?? 0);
    }
    final out = int.tryParse(_outputCtl.text.trim()) ?? 0;
    return (total, out > 0 ? total / out : 0);
  }

  Future<void> _save() async {
    final s = S.of(context);
    final output = int.tryParse(_outputCtl.text.trim()) ?? 0;
    if (output <= 0) {
      _showSnack(s.recipeValidationOutput);
      return;
    }
    if (_entries.isEmpty) {
      _showSnack(s.recipeValidationIngredients);
      return;
    }
    for (final e in _entries) {
      if (_qty(e) <= 0) {
        _showSnack(s.recipeValidationQuantityMissing);
        e.focusNode.requestFocus();
        return;
      }
    }
    if (_entries.length == 1) {
      final proceed = await confirmSingleIngredientDialog(context);
      if (!proceed || !mounted) return;
    }

    setState(() => _isSaving = true);
    final ok = await ref
        .read(recipeProvider.notifier)
        .update(
          id: widget.recipe.id,
          outputQuantity: output,
          ingredients: [
            for (final e in _entries)
              {'ingredient_id': e.ingredientId!, 'quantity': _qty(e)},
          ],
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      _showSnack(s.recipeUpdateSuccess, error: false);
      context.pop();
    } else {
      _showSnack(s.recipeErrorSnackbar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final all = ref.watch(ingredientProvider).items;
    final addedIds = _entries
        .map((e) => e.ingredientId)
        .whereType<String>()
        .toSet();
    final available = all.where((i) => !addedIds.contains(i.id)).toList();
    final unit = _unitInlineName();
    final (total, perUnit) = _preview(all);
    final bottomPad = 24 + MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
        title: Text(
          s.recipeEditTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipe.productDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.recipeEditHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _outputCtl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: unit.isNotEmpty
                              ? s.recipeOutputLabelDynamic(unit)
                              : s.recipeOutputLabel,
                          suffixText: s.pcs,
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: cs.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: cs.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _PreviewCard(
                  title: s.recipeEditPreviewTitle,
                  batchLabel: s.recipeCardStatTitleBatchCost,
                  batchValue:
                      '${formatRecipeMoney(context, total)} ${s.currency}',
                  unitLabel: s.recipeCardStatTitleUnitCost,
                  unitValue:
                      '${formatRecipeMoney(context, perUnit)} ${s.currency}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          IngredientChipCarousel(
            available: available,
            onTap: _onChipTap,
            onCreateNew: () async {
              final saved = await showIngredientFormSheet(context);
              if (saved && mounted) setState(() {});
            },
            newLabel: s.recipeCreateNewIngredientShort,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _entries.isEmpty
                ? RecipeInfoBox(
                    text: s.recipeValidationIngredients,
                    icon: Icons.arrow_upward_rounded,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(_entries.length, (i) {
                      final entry = _entries[i];
                      IngredientModel? ing;
                      for (final x in all) {
                        if (x.id == entry.ingredientId) {
                          ing = x;
                          break;
                        }
                      }
                      // Ro'yxat hali yuklanmagan bo'lsa — retseptdagi nomni
                      // ko'rsatamiz.
                      final fallback = widget.recipe.ingredients
                          .where((ri) => ri.ingredientId == entry.ingredientId)
                          .map((ri) => ri.ingredient)
                          .firstOrNull;
                      final name = ing?.name ?? fallback?.name ?? '—';
                      final unitLine =
                          ing?.displayUnitLine ??
                          fallback?.displayUnitLine ??
                          '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IngredientEntryTile(
                          name: name,
                          controller: entry.quantityController,
                          focusNode: entry.focusNode,
                          unitCode: _capitalizeUnitCode(unitLine),
                          onChanged: () => setState(() {}),
                          onRemove: () => _removeEntry(i),
                          onSubmitted: () => FocusScope.of(context).unfocus(),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Jonli tannarx kartasi — partiya va bir dona uchun.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.batchLabel,
    required this.batchValue,
    required this.unitLabel,
    required this.unitValue,
  });

  final String title;
  final String batchLabel;
  final String batchValue;
  final String unitLabel;
  final String unitValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget cell(String label, String value, Color accent) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          cell(batchLabel, batchValue, AppColors.gold),
          const SizedBox(width: 8),
          cell(unitLabel, unitValue, AppColors.info),
        ],
      ),
    );
  }
}
