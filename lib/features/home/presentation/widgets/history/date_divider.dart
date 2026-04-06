import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_spacing.dart';

/// Kartalar orasida sana ajratgich.
class HistoryDateDivider extends StatelessWidget {
  const HistoryDateDivider({
    super.key,
    required this.dateIso,
  });

  final String dateIso;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final tag = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    final dt = DateTime.tryParse(
      dateIso.length >= 10 ? dateIso.substring(0, 10) : dateIso,
    );
    if (dt == null) return const SizedBox.shrink();
    final text = DateFormat.yMMMEd(tag).format(dt);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              color: cs.outline.withValues(alpha: 0.22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              color: cs.outline.withValues(alpha: 0.22),
            ),
          ),
        ],
      ),
    );
  }
}
