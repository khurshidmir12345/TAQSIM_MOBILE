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
import '../../../auth/domain/providers/auth_provider.dart';

const _uz = AppCountries.uz;

/// Telefon raqamni almashtirish: yangi raqam → SMS kodi.
///
/// Raqam faqat kod tasdiqlangandan keyin almashadi. Kod noto'g'ri bo'lsa yoki
/// foydalanuvchi oqimni tashlab ketsa — eski raqam tasdiqlangan holida qoladi
/// (server ham shunday ishlaydi, bu yerda faqat UI aks ettiriladi).
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

enum _Step { phone, code }

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _phoneController = TextEditingController();
  final _otpKey = GlobalKey<OtpInputState>();

  _Step _step = _Step.phone;
  String _fullPhone = '';
  String _code = '';
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
    if (_phoneController.text.trim().isEmpty) return;
    if (ref.read(authProvider).isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    _fullPhone = _uz.dialCode + _phoneController.text.replaceAll(' ', '');

    final ok = await ref
        .read(authProvider.notifier)
        .sendPhoneChangeCode(_fullPhone);

    if (!mounted) return;

    if (!ok) {
      setState(() => _error = ref.read(authProvider).error);

      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _step = _Step.code);
    _startCountdown();
  }

  Future<void> _confirm() async {
    if (_code.length < 4) return;
    // Kod avtomatik to'lganda `onCompleted` va tugma birga ishlab ketmasin.
    if (ref.read(authProvider).isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    final ok = await ref
        .read(authProvider.notifier)
        .changePhone(phone: _fullPhone, code: _code);

    if (!mounted) return;

    if (!ok) {
      // Kod noto'g'ri — qayta kiritish uchun maydon tozalanadi. Raqam
      // o'zgarmagani uchun boshqa hech narsani tiklash shart emas.
      setState(() {
        _error = ref.read(authProvider).error;
        _code = '';
      });
      _otpKey.currentState?.clear();

      return;
    }

    HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    final message = S.of(context).changePhoneSuccess;

    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _back() {
    if (_step == _Step.phone) {
      context.pop();

      return;
    }

    setState(() {
      _error = null;
      _code = '';
      _step = _Step.phone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final currentPhone = authState.user?.phone;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _back,
        ),
        title: Text(
          s.changePhoneTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
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
                    if (currentPhone != null && currentPhone.isNotEmpty)
                      _CurrentPhoneCard(phone: currentPhone),
                    const SizedBox(height: 24),
                    Text(
                      _step == _Step.phone
                          ? s.changePhoneNewTitle
                          : s.changePhoneCodeTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _step == _Step.phone
                          ? s.changePhoneNewSubtitle
                          : s.otpSentTo(_fullPhone),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_step == _Step.phone)
                      CountryPhoneInput(
                        phoneController: _phoneController,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? s.enterPhone : null,
                      )
                    else
                      OtpInput(
                        key: _otpKey,
                        onChanged: (code) => setState(() => _code = code),
                        onCompleted: (code) {
                          setState(() => _code = code);
                          _confirm();
                        },
                      ),
                    const SizedBox(height: 16),
                    _NoticeBanner(message: s.changePhoneNotice),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    _PrimaryButton(
                      label: _step == _Step.phone
                          ? s.changePhoneSendCode
                          : s.changePhoneConfirm,
                      enabled: _step == _Step.phone
                          ? _phoneController.text.trim().isNotEmpty
                          : _code.length >= 4,
                      isLoading: isLoading,
                      onTap: _step == _Step.phone ? _sendCode : _confirm,
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
}

/// Joriy (tasdiqlangan) raqam — foydalanuvchi nimani almashtirayotganini
/// ko'rib tursin.
class _CurrentPhoneCard extends StatelessWidget {
  const _CurrentPhoneCard({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phone_rounded,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.changePhoneCurrent,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
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
