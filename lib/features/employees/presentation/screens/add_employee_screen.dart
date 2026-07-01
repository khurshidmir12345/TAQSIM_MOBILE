import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      _snack(e.message, error: true);
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
        _snack(e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              label: s.addEmployee,
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
