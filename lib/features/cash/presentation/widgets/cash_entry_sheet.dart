import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/cash_model.dart';
import '../../domain/providers/cash_provider.dart';

/// Yozuv tafsiloti — bosilganda ochiladi.
///
/// Qo'lda kiritilgan yozuvda summa va izohni shu yerdan o'zgartirish yoki
/// yozuvni o'chirish mumkin. Avtomatik yozuv faqat ko'rsatiladi: uning
/// manbasi asosiy sahifada.
class CashEntrySheet extends ConsumerStatefulWidget {
  const CashEntrySheet({
    super.key,
    required this.entry,
    required this.money,
  });

  final CashEntry entry;
  final String Function(double) money;

  static Future<void> show(
    BuildContext context,
    CashEntry entry,
    String Function(double) money,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CashEntrySheet(entry: entry, money: money),
    );
  }

  @override
  ConsumerState<CashEntrySheet> createState() => _CashEntrySheetState();
}

class _CashEntrySheetState extends ConsumerState<CashEntrySheet> {
  late final TextEditingController _amountCtl;
  late final TextEditingController _descCtl;

  bool _editing = false;
  bool _saving = false;

  CashEntry get _entry => widget.entry;

  Color get _accent => _entry.isIncome ? AppColors.income : AppColors.error;

  @override
  void initState() {
    super.initState();
    _amountCtl = TextEditingController(
      text: _entry.amount.toStringAsFixed(0),
    );
    _descCtl = TextEditingController(text: _entry.description ?? '');
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountCtl.text.trim().replaceAll(',', '.'),
    );

    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    try {
      await ref.read(cashProvider.notifier).updateEntry(
            _entry.id,
            amount: amount,
            description: _descCtl.text.trim(),
          );

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).snackbarErrorGeneric),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete() async {
    final s = S.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.cashDeleteTitle),
        content: Text(s.cashDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(cashProvider.notifier).delete(_entry.id);

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).noInternet)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final loc = Localizations.localeOf(context).toLanguageTag();
    final parsed = DateTime.tryParse(_entry.date);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _entry.isIncome
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 19,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _entry.categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        parsed == null
                            ? _entry.date
                            : DateFormat.yMMMMd(loc).format(parsed),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_editing) ...[
              TextField(
                controller: _amountCtl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: s.expenseAmountLabel,
                  suffixText: s.currency,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusLg),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: s.expenseDescriptionLabel,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusLg),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.cashSaveChanges),
              ),
            ] else ...[
              _AmountRow(
                amount: widget.money(_entry.amount),
                currency: s.currency,
                accent: _accent,
                isIncome: _entry.isIncome,
              ),
              if ((_entry.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusLg),
                  ),
                  child: Text(
                    _entry.description!.trim(),
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (_entry.isEditable)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () => setState(() => _editing = true),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: Text(s.cashEdit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(s.delete),
                      ),
                    ),
                  ],
                )
              else
                // Avtomatik yozuv manbasi asosiy sahifada — sababini aytamiz.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusLg),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 17,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.cashAutoEntryHint,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.amount,
    required this.currency,
    required this.accent,
    required this.isIncome,
  });

  final String amount;
  final String currency;
  final Color accent;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${isIncome ? '+' : '−'}$amount',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: accent,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          currency,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
