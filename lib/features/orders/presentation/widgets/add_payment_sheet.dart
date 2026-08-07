import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/customer_order_model.dart';
import '../../domain/providers/order_provider.dart';
import '../../domain/utils/money_utils.dart';
import '../../domain/utils/orders_api_utils.dart';

Future<bool?> showAddPaymentSheet(
  BuildContext context, {
  required CustomerOrderModel order,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AddPaymentSheet(order: order),
  );
}

class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet({required this.order});

  final CustomerOrderModel order;

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  late DateTime _paidAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paidAt = DateTime.now();
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  double get _remaining => roundMoney(parseAmount(widget.order.remainingAmount));

  /// Butun son bo'lsa ".0"siz yoziladi (masalan, 500000).
  String _editable(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  String _fmt(num v) {
    final l = Localizations.localeOf(context);
    final tag = localeTagFrom(l.languageCode, l.countryCode);
    return formatMoneyAmount(v, localeTag: tag);
  }

  String get _paidAtLabel {
    final l = Localizations.localeOf(context);
    final tag = localeTagFrom(l.languageCode, l.countryCode);
    final date = formatDateOnlyLocale(toDateString(_paidAt), localeTag: tag);
    final time = TimeOfDay.fromDateTime(_paidAt).format(context);
    return '$date · $time';
  }

  Future<void> _pickDateTime() async {
    FocusScope.of(context).unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      // To'lov sanasi kelajakda bo'lishi mumkin emas.
      lastDate: DateTime.now(),
      // Faqat kalendar — qo'lda yozish rejimida noto'g'ri format xatosi chiqadi.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_paidAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _paidAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final remaining = _remaining;
    final parsed = roundMoney(double.tryParse(_amountCtl.text.trim()) ?? 0);
    final s = S.of(context);

    if (parsed <= 0) return;
    if (parsed > remaining) {
      setState(() => _error = s.ordersPaymentExceeds);
      return;
    }

    try {
      final updated = await ref.read(orderMutationsProvider.notifier).addPayment(
            widget.order.id,
            amount: parsed,
            paidAt: toLocalDateTimeString(_paidAt),
            note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
          );
      if (!mounted) return;
      if (updated == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.ordersPaymentAdded)));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = ordersUserErrorMessage(e, s));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final remaining = _remaining;
    final busy = ref.watch(orderMutationsProvider);

    // Scroll ichida — klaviatura ochilganda ham saqlash tugmasi ko'rinadi.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.ordersAddPayment,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // Qoldiq — ixcham badge.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${s.ordersRemainingLabel}: ${_fmt(remaining)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: s.ordersPaymentAmountLabel,
            controller: _amountCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            prefixIcon: const Icon(Icons.payments_outlined, size: 20),
            // "Hammasi" — maydon ichida, alohida qator egallamaydi.
            suffixIcon: TextButton(
              onPressed: busy
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() => _amountCtl.text = _editable(remaining));
                    },
              child: Text(
                s.ordersFillAll,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          // To'lov vaqti — ixcham chip, to'liq input emas.
          Row(
            children: [
              Material(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: busy ? null : _pickDateTime,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 15,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _paidAtLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          AppTextField(
            hint: s.ordersPaymentNoteLabel,
            controller: _noteCtl,
            prefixIcon: const Icon(Icons.notes_outlined, size: 20),
            textInputAction: TextInputAction.done,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: s.actionSave,
            isLoading: busy,
            onPressed: busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
