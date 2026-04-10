import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/country_phone.dart';
import '../../../../core/widgets/country_phone_input.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../../../core/widgets/taqsim_logo_asset.dart';
import '../../domain/providers/auth_provider.dart';

enum _Step { phone, otp, profile }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  _Step _step = _Step.phone;

  // Step 1 — Phone
  CountryPhone _country = AppCountries.uz;
  final _phoneController = TextEditingController();

  // Step 2 — OTP
  String _otpCode = '';
  String? _debugCode;
  int _resendCountdown = 120;
  Timer? _timer;
  // Step 3 — Profile
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  String get _fullPhone =>
      _country.dialCode + _phoneController.text.replaceAll(' ', '');

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Step 1: send code ────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    if (_phoneController.text.replaceAll(' ', '').length <
        _country.maxDigits) {
      _showError('Telefon raqamni to\'liq kiriting');
      return;
    }

    try {
      final result =
          await ref.read(authProvider.notifier).sendCodeWithResult(_fullPhone);

      if (!mounted) return;

      if (result.phoneExists) {
        _showPhoneExistsBanner();
        return;
      }

      setState(() {
        _debugCode = result.debugCode;
        _step = _Step.otp;
      });
      _startCountdown();
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── Step 2: verify OTP ───────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) return;
    setState(() => _step = _Step.profile);
    _timer?.cancel();
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;
    try {
      final result =
          await ref.read(authProvider.notifier).sendCodeWithResult(_fullPhone);
      if (!mounted) return;
      setState(() {
        _debugCode = result.debugCode;
        _otpCode = '';
        _resendCountdown = 120;
      });
      _startCountdown();
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── Step 3: register ─────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          phone: _fullPhone,
          code: _otpCode,
          password: _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      await ref.read(shopProvider.notifier).loadShops();
      if (!mounted) return;
      final shops = ref.read(shopProvider).shops;
      context.go(shops.isEmpty ? '/shop-select' : '/shell');
    } else {
      final err = ref.read(authProvider).error;
      if (err != null && err.contains('409')) {
        _showPhoneExistsBanner();
      } else {
        _showError(err ?? 'Xatolik yuz berdi');
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _startCountdown() {
    _timer?.cancel();
    _resendCountdown = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCountdown <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showPhoneExistsBanner() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.info_outline_rounded,
            color: AppColors.primary, size: 40),
        title: const Text('Raqam ro\'yxatdan o\'tgan',
            textAlign: TextAlign.center),
        content: Text(
          '$_fullPhone raqami allaqachon ro\'yxatdan o\'tgan.\n\nUshbu raqam bilan tizimga kiring.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 44),
            ),
            child: const Text('Kirish'),
          ),
        ],
      ),
    );
  }

  void _back() {
    if (_step == _Step.otp) {
      _timer?.cancel();
      setState(() => _step = _Step.phone);
    } else if (_step == _Step.profile) {
      setState(() => _step = _Step.otp);
      _startCountdown();
    } else {
      context.go('/login');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    _Step.phone => _PhoneStep(
                        country: _country,
                        phoneController: _phoneController,
                        onCountryChanged: (c) =>
                            setState(() => _country = c),
                        onNext: _sendCode,
                        isLoading: authState.isLoading,
                        onLoginTap: () => context.go('/login'),
                      ),
                    _Step.otp => _OtpStep(
                        phone: _fullPhone,
                        debugCode: _debugCode,
                        countdown: _resendCountdown,
                        onCompleted: (code) {
                          setState(() => _otpCode = code);
                          _verifyOtp();
                        },
                        onChanged: (code) =>
                            setState(() => _otpCode = code),
                        onResend: _resendCode,
                      ),
                    _Step.profile => _ProfileStep(
                        formKey: _formKey,
                        nameController: _nameController,
                        passwordController: _passwordController,
                        confirmController: _confirmController,
                        obscurePass: _obscurePass,
                        obscureConfirm: _obscureConfirm,
                        onTogglePass: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        onToggleConfirm: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                        onRegister: _register,
                        isLoading: authState.isLoading,
                        error: authState.error,
                      ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final stepIndex = _step.index;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 16,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.splashGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _back,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                height: 44,
                child: const TaqsimLogoAsset(clipRadius: 12),
              ),
              const SizedBox(width: 12),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Step indicator
          Row(
            children: List.generate(3, (i) {
              final isDone = i < stepIndex;
              final isActive = i == stepIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _stepLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }

  String get _stepLabel {
    return switch (_step) {
      _Step.phone   => '1/3  •  Telefon raqam',
      _Step.otp     => '2/3  •  Tasdiqlash kodi',
      _Step.profile => '3/3  •  Ma\'lumotlar',
    };
  }
}

// ─── Step 1: Phone ────────────────────────────────────────────────────────

class _PhoneStep extends StatelessWidget {
  final CountryPhone country;
  final TextEditingController phoneController;
  final ValueChanged<CountryPhone> onCountryChanged;
  final VoidCallback onNext;
  final bool isLoading;
  final VoidCallback onLoginTap;

  const _PhoneStep({
    required this.country,
    required this.phoneController,
    required this.onCountryChanged,
    required this.onNext,
    required this.isLoading,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ro\'yxatdan o\'tish',
            style: theme.textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Telefon raqamingizni kiriting.\nTasdiqlash kodi yuboriladi.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(height: 1.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        CountryPhoneInput(
          selectedCountry: country,
          phoneController: phoneController,
          onCountryChanged: onCountryChanged,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onNext,
            child: isLoading
                ? const _LoadingIndicator()
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Kodni olish'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Akkaunt bor? ',
                style: theme.textTheme.bodyMedium),
            GestureDetector(
              onTap: onLoginTap,
              child: Text(
                'Kirish',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Step 2: OTP ──────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String phone;
  final String? debugCode;
  final int countdown;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String> onChanged;
  final VoidCallback onResend;

  const _OtpStep({
    required this.phone,
    required this.debugCode,
    required this.countdown,
    required this.onCompleted,
    required this.onChanged,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResend = countdown <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sms_outlined,
              color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 20),
        Text(
          'Kodni kiriting',
          style: theme.textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: '6 xonali tasdiqlash kodi\n'),
              TextSpan(
                text: phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const TextSpan(text: '\nraqamiga yuborildi.'),
            ],
          ),
        ),
        if (kDebugMode && debugCode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bug_report_rounded,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'DEBUG KOD: $debugCode',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 36),
        OtpInput(
          length: 6,
          onCompleted: onCompleted,
          onChanged: onChanged,
        ),
        const SizedBox(height: 36),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: canResend
              ? TextButton.icon(
                  key: const ValueKey('resend'),
                  onPressed: onResend,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Kodni qayta yuborish'),
                )
              : Text(
                  key: const ValueKey('countdown'),
                  'Qayta yuborish: ${_formatCountdown(countdown)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      ],
    );
  }

  String _formatCountdown(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Step 3: Profile ──────────────────────────────────────────────────────

class _ProfileStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final VoidCallback onRegister;
  final bool isLoading;
  final String? error;

  const _ProfileStep({
    required this.formKey,
    required this.nameController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onRegister,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profilingiz',
              style: theme.textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Ism va parol kiriting.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ism va familiya',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ism kiriting' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePass,
            decoration: InputDecoration(
              hintText: 'Parol (kamida 6 ta belgi)',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onTogglePass,
              ),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Kamida 6 ta belgi'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: confirmController,
            obscureText: obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Parolni tasdiqlang',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onToggleConfirm,
              ),
            ),
            validator: (v) => v != passwordController.text
                ? 'Parollar mos emas'
                : null,
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ErrorBox(message: error!),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onRegister,
              child: isLoading
                  ? const _LoadingIndicator()
                  : const Text('Ro\'yxatdan o\'tish'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared ────────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
          strokeWidth: 2.5, color: Colors.white),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
