import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/cash_model.dart';
import '../../domain/providers/cash_provider.dart';

/// Kassa sozlamalari — asosiy sahifadagi amallar kassaga ko'chirilsinmi.
///
/// Tugma bosilishi bilan server avvalgi yozuvlarni ham qayta quradi, shuning
/// uchun natija darhol ro'yxatda ko'rinadi.
class CashSettingsSheet extends ConsumerWidget {
  const CashSettingsSheet({super.key, required this.settings});

  final CashSettings settings;

  static Future<void> show(BuildContext context, CashSettings settings) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CashSettingsSheet(settings: settings),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    // Sozlama serverdan kelgan holatga ergashadi — sheet ochiq turganda ham
    // yangilanib boradi.
    final live = ref.watch(cashProvider).asData?.value.settings ?? settings;
    final notifier = ref.read(cashProvider.notifier);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.cashSettingsTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              s.cashSettingsSubtitle,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            _CheckTile(
              title: s.cashSettingTrackProduction,
              subtitle: s.cashSettingTrackProductionDesc,
              value: live.trackProduction,
              onChanged: (v) => _apply(
                context,
                () => notifier.setSetting(trackProduction: v),
              ),
            ),
            const SizedBox(height: 10),
            _CheckTile(
              title: s.cashSettingTrackReturns,
              subtitle: s.cashSettingTrackReturnsDesc,
              value: live.trackReturns,
              onChanged: (v) => _apply(
                context,
                () => notifier.setSetting(trackReturns: v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(BuildContext context, Future<void> Function() action) async {
    HapticFeedback.selectionClick();

    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).noInternet)),
      );
    }
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Checkbox.adaptive(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
