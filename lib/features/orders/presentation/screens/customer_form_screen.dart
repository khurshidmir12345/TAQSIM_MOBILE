import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/country_phone_input.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/providers/order_provider.dart';
import '../../domain/utils/orders_api_utils.dart';
import '../widgets/manage_orders_guard.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final CustomerModel? customer;

  bool get isEdit => customer != null;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _nameCtl.text = c.name;
      if (c.phone != null) _phoneCtl.text = c.phone!;
      if (c.note != null) _noteCtl.text = c.note!;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  String? _normalizePhone(String raw) {
    if (raw.trim().isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998')) return '+$digits';
    if (digits.length == 9) return '+998$digits';
    return raw;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final s = S.of(context);
    final name = _nameCtl.text.trim();
    final phone = _normalizePhone(_phoneCtl.text);
    final note = _noteCtl.text.trim();

    try {
      if (widget.isEdit) {
        final updated = await ref
            .read(orderMutationsProvider.notifier)
            .updateCustomer(
              widget.customer!.id,
              name: name,
              phone: phone,
              note: note.isEmpty ? null : note,
            );
        if (updated == null || !mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.customersUpdated)));
        context.pop(updated);
      } else {
        final created = await ref
            .read(orderMutationsProvider.notifier)
            .createCustomer(
              name: name,
              phone: phone,
              note: note.isEmpty ? null : note,
            );
        if (created == null || !mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.customersCreated)));
        context.pop(created);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ordersUserErrorMessage(e, s))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final busy = ref.watch(orderMutationsProvider);

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEdit ? s.customersEditTitle : s.customersNewTitle,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppTextField(
                label: s.customersNameLabel,
                controller: _nameCtl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.fieldRequired : null,
              ),
              const SizedBox(height: AppSpacing.md),
              CountryPhoneInput(phoneController: _phoneCtl),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: s.customersNoteLabel,
                controller: _noteCtl,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: s.actionSave,
                isLoading: busy,
                onPressed: busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
