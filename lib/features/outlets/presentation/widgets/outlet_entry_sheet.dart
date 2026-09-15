import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../setup/domain/models/bread_category_model.dart';
import '../../../setup/domain/providers/setup_provider.dart';
import '../../data/outlets_repository.dart';
import '../../domain/models/outlet_model.dart';
import '../../domain/providers/outlet_provider.dart';
import 'outlet_format.dart';

/// Daftarga yozuv: mahsulot berish / qaytarish (mahsulot ro'yxati + miqdor)
/// yoki to'lov (summa). `true` — saqlandi.
Future<bool> showOutletEntrySheet(
  BuildContext context, {
  required String outletId,
  required OutletEntryType type,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OutletEntrySheet(outletId: outletId, type: type),
  );
  return ok ?? false;
}

class _OutletEntrySheet extends ConsumerStatefulWidget {
  const _OutletEntrySheet({required this.outletId, required this.type});

  final String outletId;
  final OutletEntryType type;

  @override
  ConsumerState<_OutletEntrySheet> createState() => _OutletEntrySheetState();
}

class _OutletEntrySheetState extends ConsumerState<_OutletEntrySheet> {
  DateTime _date = DateTime.now();
  final _amountCtl = TextEditingController();
  final _paidCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  /// Mahsulot id → (miqdor, narx) kontrollerlari.
  final Map<String, TextEditingController> _qty = {};
  final Map<String, TextEditingController> _price = {};
  bool _saving = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    _paidCtl.dispose();
    _noteCtl.dispose();
    for (final c in _qty.values) {
      c.dispose();
    }
    for (final c in _price.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _qtyCtl(String id) =>
      _qty.putIfAbsent(id, TextEditingController.new);

  TextEditingController _priceCtl(BreadCategoryModel c) =>
      _price.putIfAbsent(c.id, () {
        final p = double.tryParse(c.sellingPrice) ?? 0;
        return TextEditingController(
          text: p == p.truncateToDouble() ? p.toInt().toString() : p.toString(),
        );
      });

  double _total(List<BreadCategoryModel> cats) {
    var sum = 0.0;
    for (final c in cats) {
      final q = parseDecimalInput(_qtyCtl(c.id).text) ?? 0;
      final p = parseDecimalInput(_priceCtl(c).text) ?? 0;
      sum += q * p;
    }
    return sum;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _save(List<BreadCategoryModel> cats) async {
    final s = S.of(context);
    final type = widget.type;
    final items = <OutletItemInput>[];
    double? amount;
    double? paid;

    if (type.hasItems) {
      for (final c in cats) {
        final q = parseDecimalInput(_qtyCtl(c.id).text) ?? 0;
        if (q <= 0) continue;
        items.add((
          breadCategoryId: c.id,
          quantity: q,
          unitPrice: parseDecimalInput(_priceCtl(c).text),
        ));
      }
      if (items.isEmpty) {
        _snack(s.outletValidationItems);
        return;
      }
      if (type == OutletEntryType.delivery) {
        paid = parseDecimalInput(_paidCtl.text) ?? 0;
        if (paid > _total(cats) + 0.005) {
          _snack(s.outletPaidExceeds);
          return;
        }
      }
    } else {
      amount = parseDecimalInput(_amountCtl.text) ?? 0;
      if (amount <= 0) {
        _snack(s.outletValidationAmount);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(outletLedgerProvider(widget.outletId).notifier)
          .addEntry(
            type: type,
            date: _date,
            items: items,
            amount: amount,
            paidAmount: paid,
            note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
          );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e is ApiException ? e.message : s.snackbarErrorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cats = ref.watch(breadCategoryProvider).items;
    final cur = outletCurrency(ref, s);
    final type = widget.type;

    final (title, color, icon) = switch (type) {
      OutletEntryType.delivery => (
        s.outletDeliverTitle,
        AppColors.primary,
        Icons.local_shipping_outlined,
      ),
      OutletEntryType.returned => (
        s.outletReturnTitle,
        AppColors.warning,
        Icons.undo_rounded,
      ),
      OutletEntryType.payment => (
        s.outletPayTitle,
        AppColors.success,
        Icons.payments_outlined,
      ),
    };

    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    // Sana — chip.
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                      ),
                      label: Text(outletDateLabelOf(context, _date)),
                      onPressed: _saving ? null : _pickDate,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  children: [
                    if (type.hasItems) ...[
                      Text(
                        s.outletItemsHint,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (cats.isEmpty)
                        Text(
                          s.productCategoriesEmptySubtitle,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      for (final c in cats)
                        _ItemRow(
                          category: c,
                          qtyCtl: _qtyCtl(c.id),
                          priceCtl: _priceCtl(c),
                          currency: cur,
                          onChanged: () => setState(() {}),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            s.outletTotalLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${outletMoney(context, _total(cats))} $cur',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      if (type == OutletEntryType.delivery) ...[
                        const SizedBox(height: 12),
                        _AmountField(
                          controller: _paidCtl,
                          label: s.outletPaidNowLabel,
                          hint: s.outletPaidNowHint,
                          suffix: cur,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ] else ...[
                      _AmountField(
                        controller: _amountCtl,
                        label: s.outletAmountLabel,
                        hint: '0',
                        suffix: cur,
                        autofocus: true,
                        big: true,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteCtl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: s.outletNoteLabel,
                        isDense: true,
                        prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(cats),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mahsulot qatori: nom · narx (tahrirlanadi) · miqdor.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.category,
    required this.qtyCtl,
    required this.priceCtl,
    required this.currency,
    required this.onChanged,
  });

  final BreadCategoryModel category;
  final TextEditingController qtyCtl;
  final TextEditingController priceCtl;
  final String currency;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final active = (parseDecimalInput(qtyCtl.text) ?? 0) > 0;

    InputDecoration deco(String? suffix) => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      suffixText: suffix,
      suffixStyle: TextStyle(
        fontSize: 11,
        color: cs.onSurface.withValues(alpha: 0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.16)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withValues(alpha: 0.06) : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.4)
              : cs.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextField(
              controller: priceCtl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [DecimalTextInputFormatter()],
              textAlign: TextAlign.right,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
              decoration: deco(currency),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: qtyCtl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [DecimalTextInputFormatter()],
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              decoration: deco(s.pcs).copyWith(hintText: '0'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.onChanged,
    this.autofocus = false,
    this.big = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final VoidCallback onChanged;
  final bool autofocus;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [DecimalTextInputFormatter()],
      onChanged: (_) => onChanged(),
      textAlign: big ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: big ? 28 : 16,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: big ? 18 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}
