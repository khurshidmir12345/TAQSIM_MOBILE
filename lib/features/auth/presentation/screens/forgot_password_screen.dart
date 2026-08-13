import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/models/country_phone.dart';
import '../../../../core/widgets/country_phone_input.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../domain/providers/auth_provider.dart';

const _uz = AppCountries.uz;

/// Parolni tiklash: telefon → SMS kodi → yangi parol.
///
/// Uchala qadam bitta ekranda ketma-ket almashadi — ortga qaytish va oqimni
/// kuzatish oson bo'lsin. Klaviatura ochilganda tugmalar to'silib qolmasligi
/// uchun kontent aylanadi va bo'sh joyga bosilganda klaviatura yopiladi.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { phone, code }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpKey = GlobalKey<OtpInputState>();

  _Step _step = _Step.phone;
  String _fullPhone = '';
  String _code = '';
  bool _sending = false;
  String? _error;

  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();

        return;
      }

      setState(() => _resendCountdown--);

      if (_resendCountdown <= 0) timer.cancel();
    });
  }

  // ─── Qadamlar ──────────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    _fullPhone = _uz.dialCode + _phoneController.text.replaceAll(' ', '');

    final ok = await ref.read(authProvider.notifier).sendCode(_fullPhone);

    if (!mounted) return;

    setState(() => _sending = false);

    if (!ok) {
      setState(() => _error = ref.read(authProvider).error);

      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _step = _Step.code);
    _startCountdown();
  }

  /// Kod tasdiqlanishi bilan tizimga kiriladi — parol shu yerda so'ralmaydi.
  ///
  /// Ilgari shu joydan parol qadamiga o'tilardi va foydalanuvchi ikki marta
  /// parol yozguncha kodning 2 daqiqasi o'tib ketardi. Endi parol ilova
  /// ichida, shoshilmasdan qo'yiladi.
  Future<void> _onCodeCompleted(String code) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _code = code;
      _error = null;
    });

    final ok = await ref
        .read(authProvider.notifier)
        .loginWithCode(phone: _fullPhone, code: code);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _error = ref.read(authProvider).error;
        _code = '';
      });
      _otpKey.currentState?.clear();

      return;
    }

    // Router `mustSetPassword` ni ko'rib parol o'rnatish ekraniga o'tkazadi.
  }

  void _back() {
    if (_step == _Step.phone) {
      context.pop();

      return;
    }

    setState(() {
      _error = null;
      _step = _Step.phone;
    });
  }

  // ─── Tekshiruvlar ──────────────────────────────────────────────────────


  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isLoading = ref.watch(authProvider).isLoading || _sending;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _back,
        ),
        title: Text(
          s.forgotPasswordTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      // Bo'sh joyga bosilganda klaviatura yopiladi.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              // Klaviatura ochilganda tugma ostida qolmasin.
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepDots(current: _step.index),
                    const SizedBox(height: 24),
                    Text(
                      switch (_step) {
                        _Step.phone => s.forgotPasswordPhoneTitle,
                        _Step.code => s.forgotPasswordCodeTitle,
                      },
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      switch (_step) {
                        _Step.phone => s.forgotPasswordPhoneSubtitle,
                        _Step.code => s.otpSentTo(_fullPhone),
                      },
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ..._stepBody(s),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    _PrimaryButton(
                      label: switch (_step) {
                        _Step.phone => s.forgotPasswordSendCode,
                        _Step.code => s.continueWizard,
                      },
                      enabled: switch (_step) {
                        _Step.phone => _phoneController.text.trim().isNotEmpty,
                        _Step.code => _code.length >= 4,
                      },
                      isLoading: isLoading,
                      onTap: switch (_step) {
                        _Step.phone => _sendCode,
                        _Step.code => () => _onCodeCompleted(_code),
                      },
                    ),
                    if (_step == _Step.code) ...[
                      const SizedBox(height: 12),
                      _ResendRow(
                        countdown: _resendCountdown,
                        onResend: _resendCountdown > 0 ? null : _sendCode,
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _stepBody(S s) {
    return switch (_step) {
      _Step.phone => [
        CountryPhoneInput(
          phoneController: _phoneController,
          validator: (v) => (v == null || v.isEmpty) ? s.enterPhone : null,
        ),
      ],
      _Step.code => [
        OtpInput(
          key: _otpKey,
          onChanged: (code) => setState(() => _code = code),
          onCompleted: _onCodeCompleted,
        ),
      ],
    };
  }
}

/// Uch qadamli oqim ko'rsatkichi.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(3, (i) {
        final active = i <= current;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : cs.outline.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.countdown, this.onResend});

  final int countdown;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Center(
      child: countdown > 0
          ? Text(
              s.resendIn('$countdown'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
          : TextButton(onPressed: onResend, child: Text(s.resendCode)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: enabled && !isLoading ? onTap : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
