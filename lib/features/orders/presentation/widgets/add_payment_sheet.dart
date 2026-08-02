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
  final _paidAtDisplayCtl = TextEditingController();
  late DateTime _paidAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paidAt = DateTime.now();
    _paidAtDisplayCtl.text = toLocalDateTimeString(_paidAt);
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    _paidAtDisplayCtl.dispose();
    super.dispose();
  }

  double get _remaining => roundMoney(parseAmount(widget.order.remainingAmount));

  String _fmt(num v) {
    final l = Localizations.localeOf(context);
    final tag = localeTagFrom(l.languageCode, l.countryCode);
    return formatMoneyAmount(v, localeTag: tag);
  }

  void _syncPaidAtDisplay() {
    _paidAtDisplayCtl.text =
        '${toDateString(_paidAt)} ${TimeOfDay.fromDateTime(_paidAt).format(context)}';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    if (!mounted) return;
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
      _syncPaidAtDisplay();
    });
  }

  Future<void> _submit() async {
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
      setState(() => _error = ordersUserErrorMessage(e, s));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final remaining = _remaining;
    final busy = ref.watch(orderMutationsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.ordersAddPayment,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${s.ordersRemainingLabel}: ${_fmt(remaining)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: s.ordersPaymentAmountLabel,
            controller: _amountCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _amountCtl.text = remaining.toString();
                    },
              child: Text(s.ordersFillAll),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: s.ordersPaymentDateLabel,
            readOnly: true,
            onTap: busy ? null : _pickDateTime,
            controller: _paidAtDisplayCtl,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: s.ordersPaymentNoteLabel,
            controller: _noteCtl,
            maxLines: 2,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: TextStyle(color: cs.error)),
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
