import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/cash_model.dart';

/// Kassa ro'yxatidagi bitta qator.
///
/// Chapda yo'nalish belgisi, o'rtada tur va izoh, o'ngda summa. Avtomatik
/// yozuvda kichik belgi turadi — foydalanuvchi uni nega tahrirlay olmasligini
/// tushunsin.
class CashEntryTile extends StatelessWidget {
  const CashEntryTile({
    super.key,
    required this.entry,
    required this.money,
    this.onTap,
  });

  final CashEntry entry;
  final String Function(double) money;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = entry.isIncome ? AppColors.income : AppColors.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  entry.isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  size: 17,
                  color: color,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!entry.isEditable) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: s.cashAutoEntryHint,
                            child: Icon(
                              Icons.link_rounded,
                              size: 13,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (entry.description != null &&
                        entry.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.description!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.isIncome ? '+' : '−'}${money(entry.amount)}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
