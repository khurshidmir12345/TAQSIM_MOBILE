import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../domain/models/ingredient_model.dart';

/// Retsept yaratish va tahrirlash ekranlari uchun umumiy tarkib widgetlari.

/// Faqat bitta xom ashyo bilan saqlashdan oldin tasdiq. `true` — baribir saqlash.
Future<bool> confirmSingleIngredientDialog(BuildContext context) async {
  final s = S.of(context);
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

/// `25.000` → `25`, `1.50` → `1.5` — tahrirlash maydoni uchun toza ko'rinish.
String editableQuantity(String raw) {
  final d = double.tryParse(raw.replaceAll(',', '.'));
  if (d == null) return raw;
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toString();
}

class RecipeIngredientEntry {
  String? ingredientId;
  final TextEditingController quantityController;
  final FocusNode focusNode;

  RecipeIngredientEntry({
    this.ingredientId,
    required this.quantityController,
    required this.focusNode,
  });
}

class RecipeInfoBox extends StatelessWidget {
  const RecipeInfoBox({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });

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

/// 3-qadam — xom ashyo karuseli.
///
/// Birinchi element — "+ Yangi" (yangi xom ashyo yaratish), keyin mavjud
/// xom ashyolar; har biri "+" belgisi bilan — bosilsa ro'yxatga qo'shiladi.
class IngredientChipCarousel extends StatelessWidget {
  const IngredientChipCarousel({
    super.key,
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
            return NewIngredientChip(label: newLabel, onTap: onCreateNew);
          }
          final ing = available[i - 1];
          return IngredientChip(label: ing.name, onTap: () => onTap(ing));
        },
      ),
    );
  }
}

class NewIngredientChip extends StatelessWidget {
  const NewIngredientChip({
    super.key,
    required this.label,
    required this.onTap,
  });

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
class IngredientChip extends StatelessWidget {
  const IngredientChip({super.key, required this.label, required this.onTap});

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
class IngredientEntryTile extends StatelessWidget {
  const IngredientEntryTile({
    super.key,
    required this.name,
    required this.controller,
    required this.focusNode,
    required this.unitCode,
    required this.onRemove,
    required this.onSubmitted,
    this.onChanged,
  });

  final String name;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String unitCode;
  final VoidCallback onRemove;
  final VoidCallback onSubmitted;

  /// Miqdor o'zgarganda (jonli tannarx uchun).
  final VoidCallback? onChanged;

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
              onChanged: (_) => onChanged?.call(),
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
