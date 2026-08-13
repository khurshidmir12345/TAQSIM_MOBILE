import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';

/// Sahifa tepasidagi bo'lim tanlagich (kassa, statistika, zakazlar).
///
/// Uchala sahifada bir xil ko'rinishda bo'lishi uchun bitta joyda saqlanadi —
/// ilgari har biri o'z nusxasiga ega edi va fon rangi, radius, soya kabi
/// mayda farqlar bilan ajralib turardi.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> tabs;
  final String Function(T tab) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (tab == selected) return;

                  HapticFeedback.selectionClick();
                  onChanged(tab);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: tab == selected ? cs.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    // Soya faqat yorug' rejimda — qorong'ida u ko'rinmaydi,
                    // aksincha chekkalarni iflos qiladi.
                    boxShadow: tab == selected && !isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelOf(tab),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: tab == selected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
