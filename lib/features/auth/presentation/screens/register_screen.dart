import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/models/country_phone.dart';
import '../../../../core/widgets/country_phone_input.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../../../core/widgets/policy_links_hint.dart';
import '../../../../core/widgets/social_auth_section.dart';
import '../../../../core/widgets/taqsim_logo_asset.dart';
import '../../domain/providers/auth_provider.dart';

const _uz = AppCountries.uz;
const _minPassLen = 8;

enum _Step { form, otp }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  _Step _step = _Step.form;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  int _passLen = 0;
  bool _phoneHasContent = false;
  bool _nameHasContent = false;

  // OTP
  String _otpCode = '';
  int _resendCountdown = 120;
  Timer? _timer;

  String get _fullPhone =>
      _uz.dialCode + _phoneController.text.replaceAll(' ', '');

  bool get _confirmMatches =>
      _confirmController.text == _passwordController.text &&
      _confirmController.text.isNotEmpty;

  bool get _canSubmit =>
      _nameHasContent &&
      _phoneHasContent &&
      _passLen >= _minPassLen &&
      _confirmMatches;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPassChanged);
    _phoneController.addListener(_onPhoneChanged);
    _nameController.addListener(_onNameChanged);
    _confirmController.addListener(_onConfirmChanged);
  }

  void _onPassChanged() {
    final len = _passwordController.text.length;
    if (len != _passLen) setState(() => _passLen = len);
  }

  void _onPhoneChanged() {
    final has = _phoneController.text.trim().isNotEmpty;
    if (has != _phoneHasContent) setState(() => _phoneHasContent = has);
  }

  void _onNameChanged() {
    final has = _nameController.text.trim().isNotEmpty;
    if (has != _nameHasContent) setState(() => _nameHasContent = has);
  }

  void _onConfirmChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Step 1 → Step 2 ────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    try {
      final result =
          await ref.read(authProvider.notifier).sendCodeWithResult(_fullPhone);
      if (!mounted) return;

      if (result.phoneExists) {
        _showPhoneExistsDialog();
        return;
      }

      setState(() {
        _step = _Step.otp;
      });
      _startCountdown();
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  // ── OTP ────────────────────────────────────────────────────────────────

  Future<void> _verifyAndRegister() async {
    if (_otpCode.length < 4) return;

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          phone: _fullPhone,
          code: _otpCode,
          password: _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      _timer?.cancel();
      await ref.read(shopProvider.notifier).loadShops();
      if (!mounted) return;
      final shops = ref.read(shopProvider).shops;
      context.go(shops.isEmpty ? '/shop-select' : '/shell');
    } else {
      final err = ref.read(authProvider).error;
      _showSnack(err ?? S.of(context).tryAgain);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;
    try {
      await ref.read(authProvider.notifier).sendCodeWithResult(_fullPhone);
      if (!mounted) return;
      setState(() {
        _otpCode = '';
        _resendCountdown = 120;
      });
      _startCountdown();
    } catch (e) {
      _showSnack(e.toString());
    }
  }

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

  void _back() {
    if (_step == _Step.otp) {
      _timer?.cancel();
      setState(() {
        _step = _Step.form;
        _otpCode = '';
      });
    } else {
      context.go('/login');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPhoneExistsDialog() {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.info_outline_rounded,
            color: AppColors.primary, size: 40),
        title: Text(s.phoneExistsTitle, textAlign: TextAlign.center),
        content: Text(
          s.phoneExistsBody(_fullPhone),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancelShort),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            child: Text(s.loginButton),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == _Step.form
                      ? _FormStep(
                          formKey: _formKey,
                          nameController: _nameController,
                          phoneController: _phoneController,
                          passwordController: _passwordController,
                          confirmController: _confirmController,
                          obscurePass: _obscurePass,
                          obscureConfirm: _obscureConfirm,
                          passLen: _passLen,
                          confirmMatches: _confirmMatches,
                          canSubmit: _canSubmit,
                          isLoading: authState.isLoading,
                          onTogglePass: () =>
                              setState(() => _obscurePass = !_obscurePass),
                          onToggleConfirm: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          onSubmit: _sendCode,
                          onLoginTap: () => context.go('/login'),
                        )
                      : _OtpStep(
                          phone: _fullPhone,
                          countdown: _resendCountdown,
                          isLoading: authState.isLoading,
                          onCompleted: (code) {
                            setState(() => _otpCode = code);
                            _verifyAndRegister();
                          },
                          onChanged: (code) =>
                              setState(() => _otpCode = code),
                          onResend: _resendCode,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 10),
        child: Row(
          children: [
            Material(
              color: cs.surfaceContainerHighest,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _back,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: cs.onSurface, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(
                width: 40,
                height: 40,
                child: TaqsimLogoAsset(clipRadius: 11)),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Form (Ism + Telefon + Parol) ────────────────────────────────────

class _FormStep extends StatelessWidget {
  const _FormStep({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.passLen,
    required this.confirmMatches,
    required this.canSubmit,
    required this.isLoading,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onLoginTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePass;
  final bool obscureConfirm;
  final int passLen;
  final bool confirmMatches;
  final bool canSubmit;
  final bool isLoading;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sarlavha + Login chip ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  s.registerTitle,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _LoginChip(onTap: onLoginTap),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.registerSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // ── Ism ───────────────────────────────────────────────
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: s.fullNameHint,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? s.enterName : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Telefon ───────────────────────────────────────────
          CountryPhoneInput(
            phoneController: phoneController,
            validator: (v) =>
                (v == null || v.isEmpty) ? s.enterPhone : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Parol ─────────────────────────────────────────────
          TextFormField(
            controller: passwordController,
            obscureText: obscurePass,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: s.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: _PassSuffix(
                length: passLen,
                minLength: _minPassLen,
                obscure: obscurePass,
                onToggle: onTogglePass,
              ),
            ),
            validator: (v) =>
                (v == null || v.length < _minPassLen)
                    ? 'Kamida $_minPassLen ta belgi'
                    : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Parolni tasdiqlash ────────────────────────────────
          TextFormField(
            controller: confirmController,
            obscureText: obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => canSubmit ? onSubmit() : null,
            decoration: InputDecoration(
              hintText: s.confirmPasswordHint,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: _ConfirmSuffix(
                hasText: confirmController.text.isNotEmpty,
                matches: confirmMatches,
                obscure: obscureConfirm,
                onToggle: onToggleConfirm,
              ),
            ),
            validator: (v) => v != passwordController.text
                ? s.passwordsNotMatch
                : null,
          ),

          const SizedBox(height: 16),

          // ── Siyosat havolasi (button tepasida) ────────────────
          const PolicyLinksHint(isLogin: false),

          const SizedBox(height: 12),

          // ── Davom etish tugmasi ───────────────────────────────
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: canSubmit ? 1.0 : 0.45,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (canSubmit && !isLoading) ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary,
                  disabledForegroundColor: Colors.white,
                  elevation: canSubmit ? 2 : 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusLg),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          key: const ValueKey('label'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.continueWizard,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Ijtimoiy kirish ───────────────────────────────────
          const SocialAuthSection(),
        ],
      ),
    );
  }
}

// ─── Step 2: OTP ─────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.phone,
    required this.countdown,
    required this.isLoading,
    required this.onCompleted,
    required this.onChanged,
    required this.onResend,
  });

  final String phone;
  final int countdown;
  final bool isLoading;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String> onChanged;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final canResend = countdown <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ikon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sms_outlined,
              color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 20),

        Text(
          s.otpTitle,
          style: theme.textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
            children: [
              TextSpan(text: s.otpSentTo(phone)),
            ],
          ),
        ),

        const SizedBox(height: 36),

        OtpInput(
          length: 4,
          onCompleted: onCompleted,
          onChanged: onChanged,
        ),

        const SizedBox(height: 32),

        // Loading yoki Qayta yuborish
        if (isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: canResend
                ? TextButton.icon(
                    key: const ValueKey('resend'),
                    onPressed: onResend,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(s.resendCode),
                  )
                : Text(
                    key: const ValueKey('countdown'),
                    s.resendIn(_fmt(countdown)),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),

        const SizedBox(height: 24),
        _PulsingSmsHelp(
          onTap: () => _showSmsHelp(context),
        ),
      ],
    );
  }

  static String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSmsHelp(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = S.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(s.smsHelpTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                s.smsHelpCauses,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              _SmsHelpCard(
                icon: Icons.block_rounded,
                iconColor: Colors.orange,
                title: s.smsSpamTitle,
                body: s.smsSpamBody,
              ),
              const SizedBox(height: 12),
              _SmsHelpCard(
                icon: Icons.sim_card_outlined,
                iconColor: Colors.orange,
                title: s.smsBalanceTitle,
                body: s.smsBalanceBody,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.understood),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Password Suffix ──────────────────────────────────────────────────────────

class _PassSuffix extends StatelessWidget {
  const _PassSuffix({
    required this.length,
    required this.minLength,
    required this.obscure,
    required this.onToggle,
  });

  final int length;
  final int minLength;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isReady = length >= minLength;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isReady
              ? Padding(
                  key: const ValueKey('ok'),
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.success.withValues(alpha: 0.85)),
                )
              : Padding(
                  key: const ValueKey('cnt'),
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '$length/$minLength',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: length == 0
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
        ),
        IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: onToggle,
          splashRadius: 18,
        ),
      ],
    );
  }
}

// ─── Confirm Suffix ───────────────────────────────────────────────────────────

class _ConfirmSuffix extends StatelessWidget {
  const _ConfirmSuffix({
    required this.hasText,
    required this.matches,
    required this.obscure,
    required this.onToggle,
  });

  final bool hasText;
  final bool matches;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasText)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: matches
                ? Padding(
                    key: const ValueKey('ok'),
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.success.withValues(alpha: 0.85)),
                  )
                : Padding(
                    key: const ValueKey('err'),
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.cancel_rounded,
                        size: 18,
                        color: AppColors.error.withValues(alpha: 0.70)),
                  ),
          ),
        IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: onToggle,
          splashRadius: 18,
        ),
      ],
    );
  }
}

// ─── Login Chip ───────────────────────────────────────────────────────────────

class _LoginChip extends StatelessWidget {
  const _LoginChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).loginButton,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 13, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing SMS Help ─────────────────────────────────────────────────────────

class _PulsingSmsHelp extends StatefulWidget {
  const _PulsingSmsHelp({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PulsingSmsHelp> createState() => _PulsingSmsHelpState();
}

class _PulsingSmsHelpState extends State<_PulsingSmsHelp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Material(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline_rounded,
                    color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 8),
                  Text(
                  S.of(context).codeNotReceived,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.orange.shade700, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SMS Help Card ────────────────────────────────────────────────────────────

class _SmsHelpCard extends StatelessWidget {
  const _SmsHelpCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    height: 1.45,
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

