import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/models/measurement_unit_model.dart';
import '../../../auth/domain/providers/shop_provider.dart';

/// Do'konning o'z partiya birligini yaratish (stiker + nom).
///
/// Qaytaradi: yaratilgan birlik, yoki `null` — bekor qilindi / xatolik.
/// Ro'yxat [recipeBatchUnitsProvider] ichida avtomatik yangilanadi.
Future<MeasurementUnitModel?> showCustomBatchUnitSheet(BuildContext context) {
  return showModalBottomSheet<MeasurementUnitModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CustomBatchUnitSheet(),
  );
}

/// Ishlab chiqarishga mos stikerlar — foydalanuvchi bittasini tanlaydi.
const List<String> _kStickers = [
  '🧺',
  '📦',
  '🍲',
  '🔥',
  '🥘',
  '🍽️',
  '🪣',
  '🛢️',
  '🧴',
  '🫙',
  '🥡',
  '🍶',
  '🧱',
  '📏',
  '⚖️',
  '🔢',
  '🍞',
  '🥖',
  '🧁',
  '🎁',
  '🛒',
  '🚚',
  '🏭',
  '⭐',
];

class _CustomBatchUnitSheet extends ConsumerStatefulWidget {
  const _CustomBatchUnitSheet();

  @override
  ConsumerState<_CustomBatchUnitSheet> createState() =>
      _CustomBatchUnitSheetState();
}

class _CustomBatchUnitSheetState extends ConsumerState<_CustomBatchUnitSheet> {
  final _nameCtl = TextEditingController();
  String _icon = _kStickers.first;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.snackbarFillAllFields),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final unit = await ref
          .read(recipeBatchUnitsProvider.notifier)
          .addCustom(name: name, icon: _icon);
      if (!mounted) return;
      Navigator.of(context).pop(unit);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e is ApiException ? e.message : s.snackbarErrorGeneric;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Tanlangan stiker + nom — jonli ko'rinish.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(_icon, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.recipeCustomUnitTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.recipeCustomUnitSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in _kStickers)
                    _StickerCell(
                      emoji: e,
                      selected: e == _icon,
                      onTap: () => setState(() => _icon = e),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLength: 30,
                onSubmitted: (_) => _saving ? null : _submit(),
                decoration: InputDecoration(
                  hintText: s.recipeCustomUnitNameHint,
                  counterText: '',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: cs.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.actionSave,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerCell extends StatelessWidget {
  const _StickerCell({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : cs.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : cs.outline.withValues(alpha: 0.1),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 21)),
        ),
      ),
    );
  }
}
