import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/models/country_phone.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/providers/employee_provider.dart';

enum _Step { form, otp }

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  static const _uz = AppCountries.uz;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  _Step _step = _Step.form;
  bool _loading = false;
  bool _obscure = true;
  String _code = '';

  String get _fullPhone => _uz.dialCode + _phoneController.text.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _money(double v) => '${NumberFormat('#,##0', 'uz').format(v)} UZS';

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : null,
        content: Text(message),
      ));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final meta = ref.read(employeesProvider).asData?.value.meta;

    if (meta != null && !meta.hasFreeSlot) {
      final ok = await _confirmPaidSeat(meta.seatPriceLocal, meta.fridayDiscount,
          meta.fridayDiscountPercent);
      if (ok != true) return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(employeesProvider.notifier).startInvite(
            name: _nameController.text.trim(),
            phone: _fullPhone,
            password: _passwordController.text,
          );
      if (!mounted) return;
      setState(() => _step = _Step.otp);
    } on ApiException catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmCode() async {
    if (_code.length != 4) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(employeesProvider.notifier).confirm(phone: _fullPhone, code: _code);
      if (!mounted) return;
      _snack(S.of(context).employeeCreatedMsg);
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (e.isInviteExpired) {
        _snack(e.message, error: true);
        if (mounted) setState(() => _step = _Step.form);
      } else {
        _handleError(e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleError(ApiException e) {
    if (e.isInsufficientBalance) {
      _showInsufficientBalance();
    } else {
      _snack(e.message, error: true);
    }
  }

  Future<bool?> _confirmPaidSeat(double priceLocal, bool friday, int percent) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 16),
              Text(s.employeePaidConfirmTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                s.employeePaidConfirmMsg.replaceAll('{price}', _money(priceLocal)),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
              if (friday) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          size: 15, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        s.employeeFridayDiscount.replaceAll('{percent}', '$percent'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              AppButton(
                label: s.employeeContinueBtn,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: s.cancel,
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsufficientBalance() {
    final s = S.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.insufficientBalanceTitle),
        content: Text(s.insufficientBalanceMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet');
            },
            child: Text(s.topUpNow),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == _Step.form ? s.addEmployee : s.employeeConfirmTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _step == _Step.form ? _buildForm(s) : _buildOtp(s),
      ),
    );
  }

  Widget _buildForm(S s) {
    final meta = ref.watch(employeesProvider).asData?.value.meta;
    final paidMeta = (meta != null && !meta.hasFreeSlot) ? meta : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paidMeta != null) ...[
              _PaidNotice(
                text: s.employeePaidPerMonth
                    .replaceAll('{price}', _money(paidMeta.seatPriceLocal)),
                friday: paidMeta.fridayDiscount
                    ? s.employeeFridayDiscount
                        .replaceAll('{percent}', '${paidMeta.fridayDiscountPercent}')
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: s.employeeNameLabel,
              controller: _nameController,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? s.enterName : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(s.employeePhoneLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            CountryPhoneInput(
              phoneController: _phoneController,
              validator: (v) =>
                  (v == null || v.replaceAll(RegExp(r'\D'), '').length < 9)
                      ? s.enterPhone
                      : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: s.employeePasswordLabel,
              controller: _passwordController,
              obscureText: _obscure,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => (v == null || v.length < 8) ? s.enterPassword : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: paidMeta != null ? s.employeeContinueBtn : s.addEmployee,
              icon: Icons.send_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _submitForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtp(S s) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.sms_rounded, color: cs.primary, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.employeeConfirmSentTo.replaceAll('{phone}', _fullPhone),
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xl),
          OtpInput(
            onChanged: (v) => _code = v,
            onCompleted: (v) {
              _code = v;
              _confirmCode();
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: s.employeeConfirmBtn,
            isLoading: _loading,
            onPressed: _loading ? null : _confirmCode,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: s.cancel,
            variant: AppButtonVariant.text,
            onPressed: _loading ? null : () => setState(() => _step = _Step.form),
          ),
        ],
      ),
    );
  }
}

class _PaidNotice extends StatelessWidget {
  final String text;
  final String? friday;
  const _PaidNotice({required this.text, this.friday});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                if (friday != null) ...[
                  const SizedBox(height: 2),
                  Text(friday!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
