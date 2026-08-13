import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Parolni o'rnatish / o'zgartirish.
///
/// Joriy parol maydoni **shartli**:
///  - parolni unutib SMS kodi bilan kirgan foydalanuvchida (`mustSetPassword`)
///    ko'rsatilmaydi — u eski parolni ta'rifiga ko'ra bilmaydi;
///  - Google/Telegram orqali kirganda parol umuman bo'lmaydi (`hasPassword`
///    false), shuning uchun ham so'ralmaydi.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  static const _minLength = 6;

  final _currentCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _currentCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  bool get _needsCurrent {
    final user = ref.read(authProvider).user;

    if (user == null) return true;

    return user.hasPassword && !user.mustSetPassword;
  }

  bool get _valid {
    if (_passwordCtl.text.length < _minLength) return false;
    if (_passwordCtl.text != _confirmCtl.text) return false;
    if (_needsCurrent && _currentCtl.text.isEmpty) return false;

    return true;
  }

  Future<void> _submit() async {
    if (!_valid) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _error = null);

    final ok = await ref.read(authProvider.notifier).changePassword(
          currentPassword: _needsCurrent ? _currentCtl.text : null,
          newPassword: _passwordCtl.text,
        );

    if (!mounted) return;

    if (!ok) {
      setState(() => _error = ref.read(authProvider).error);

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).passwordChangedSuccess)),
    );

    // Parol o'rnatish majburiy bo'lgan holatda bu ekranga qaytarib
    // yuborilmasin — ilovaning asosiy qismiga o'tamiz.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/shell');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);
    final isLoading = ref.watch(authProvider).isLoading;
    final mustSet = ref.watch(authProvider).user?.mustSetPassword ?? false;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        // Parol o'rnatish majburiy bo'lsa orqaga tugmasi ko'rsatilmaydi.
        automaticallyImplyLeading: !mustSet,
        leading: mustSet
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.pop();
                },
              ),
        title: Text(
          mustSet ? s.setPasswordTitle : s.changePasswordTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
        children: [
          if (mustSet)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.setPasswordHint,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_needsCurrent) ...[
            _Field(
              controller: _currentCtl,
              hint: s.currentPasswordHint,
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
          ],
          _Field(
            controller: _passwordCtl,
            hint: s.newPasswordHint,
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onChanged: (_) => setState(() {}),
            helper: s.passwordMinHint,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _confirmCtl,
            hint: s.confirmPasswordHint,
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onChanged: (_) => setState(() {}),
            error: _confirmCtl.text.isNotEmpty &&
                    _confirmCtl.text != _passwordCtl.text
                ? s.passwordsNotMatch
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: cs.error, fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _valid && !isLoading ? _submit : null,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      s.actionSave,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.helper,
    this.error,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helper,
        errorText: error,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
