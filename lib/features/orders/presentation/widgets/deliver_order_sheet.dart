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

Future<bool?> showDeliverOrderSheet(
  BuildContext context, {
  required CustomerOrderModel order,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _DeliverOrderSheet(order: order),
  );
}

class _DeliverOrderSheet extends ConsumerStatefulWidget {
  const _DeliverOrderSheet({required this.order});

  final CustomerOrderModel order;

  @override
  ConsumerState<_DeliverOrderSheet> createState() => _DeliverOrderSheetState();
}

class _DeliverOrderSheetState extends ConsumerState<_DeliverOrderSheet> {
  final _amountCtl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountCtl.dispose();
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

  Future<void> _submit({required bool payLater}) async {
    FocusScope.of(context).unfocus();
    final remaining = _remaining;
    final parsed = payLater
        ? 0.0
        : roundMoney(double.tryParse(_amountCtl.text.trim()) ?? 0);
    final s = S.of(context);

    if (!payLater && parsed > 0 && parsed > remaining) {
      setState(() => _error = s.ordersPaymentExceeds);
      return;
    }

    try {
      final updated = await ref.read(orderMutationsProvider.notifier).deliverOrder(
            widget.order.id,
            paymentAmount: payLater ? null : (parsed > 0 ? parsed : null),
          );
      if (!mounted) return;
      if (updated == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.ordersDelivered)));
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

    // Scroll ichida — klaviatura ochilganda ham tugmalar ko'rinadi.
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
                  s.ordersDeliverTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
            hint: s.ordersPaymentNowLabel,
            controller: _amountCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            prefixIcon: const Icon(Icons.payments_outlined, size: 20),
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
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: s.ordersDeliverConfirm,
            isLoading: busy,
            onPressed: busy ? null : () => _submit(payLater: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (remaining > 0)
            OutlinedButton(
              onPressed: busy ? null : () => _submit(payLater: true),
              child: Text(s.ordersPayLater),
            ),
          if (remaining > 0) ...[
            const SizedBox(height: 4),
            Text(
              s.ordersPayLaterHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
