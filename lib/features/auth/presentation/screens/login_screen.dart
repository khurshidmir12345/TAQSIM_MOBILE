import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_raster_assets.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/models/country_phone.dart';
import '../../../../core/widgets/country_phone_input.dart';
import '../../../../core/widgets/policy_links_hint.dart';
import '../../../../core/widgets/social_auth_section.dart';
import '../../../../core/widgets/taqsim_logo_asset.dart';
import '../../domain/providers/auth_provider.dart';

const _uz = AppCountries.uz;
const _minPasswordLength = 8;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  int _passwordLength = 0;
  bool _phoneHasContent = false;

  bool get _canSubmit =>
      _phoneHasContent && _passwordLength >= _minPasswordLength;

  String get _fullPhone =>
      _uz.dialCode + _phoneController.text.replaceAll(' ', '');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final len = _passwordController.text.length;
      if (len != _passwordLength) {
        setState(() => _passwordLength = len);
      }
    });
    _phoneController.addListener(() {
      final has = _phoneController.text.trim().isNotEmpty;
      if (has != _phoneHasContent) {
        setState(() => _phoneHasContent = has);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          phone: _fullPhone,
          password: _passwordController.text,
        );

    if (success && mounted) {
      await ref.read(shopProvider.notifier).loadShops();
      if (!mounted) return;
      final shops = ref.read(shopProvider).shops;
      context.go(shops.isEmpty ? '/shop-select' : '/shell');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final s = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Sarlavha ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            s.welcomeBack,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _RegisterChip(onTap: () => context.go('/register')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.loginSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Telefon ──────────────────────────────────────
                    CountryPhoneInput(
                      phoneController: _phoneController,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? s.enterPhone : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Parol ────────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _canSubmit ? _login() : null,
                      decoration: InputDecoration(
                        hintText: s.password,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: _PasswordSuffix(
                          length: _passwordLength,
                          minLength: _minPasswordLength,
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? s.enterPassword : null,
                    ),

                    // ── Xato banner ──────────────────────────────────
                    if (authState.error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SmartErrorBanner(
                        message: authState.error!,
                        onRegisterTap: () => context.go('/register'),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Siyosat havolasi (button tepasida) ───────────
                    const PolicyLinksHint(isLogin: true),

                    const SizedBox(height: 12),

                    // ── Kirish tugmasi ───────────────────────────────
                    _LoginButton(
                      canSubmit: _canSubmit,
                      isLoading: authState.isLoading,
                      label: s.loginButton,
                      onTap: _login,
                    ),

                    const SizedBox(height: 8),

                    // ── Ijtimoiy kirish ──────────────────────────────
                    const SocialAuthSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final s = S.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: SizedBox(
        width: double.infinity,
        height: top + 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.primary,
              child: Image.asset(
                AppRasterAssets.appBanner,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
            // Gradient overlay — pastdan matn o'qilsin
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            // Logo + Nom
            Padding(
              padding: EdgeInsets.only(
                top: top + 20,
                bottom: 20,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const TaqsimLogoAsset(clipRadius: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.40),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.appTagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Password Suffix ──────────────────────────────────────────────────────────

class _PasswordSuffix extends StatelessWidget {
  const _PasswordSuffix({
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
        // Belgisayar: 5/8 yoki check
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isReady
              ? Padding(
                  key: const ValueKey('check'),
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.success.withValues(alpha: 0.85),
                  ),
                )
              : Padding(
                  key: const ValueKey('counter'),
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

// ─── Smart Error Banner ───────────────────────────────────────────────────────
/// Ikkita kichik kard:
///  1) Qizil — xato xabari
///  2) Ko'k  — birinchi marta kiruvchiga yo'naltiruvchi hint
class _SmartErrorBanner extends StatelessWidget {
  const _SmartErrorBanner({
    required this.message,
    required this.onRegisterTap,
  });

  final String message;
  final VoidCallback onRegisterTap;

  static const _infoBlue  = Color(0xFF1976D2);
  static const _infoBg    = Color(0xFFE8F4FD);
  static const _infoBgDark = Color(0xFF0D2D45);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Qizil xato ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 14),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ── 2. Ko'k info ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? _infoBgDark : _infoBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _infoBlue.withValues(alpha: isDark ? 0.20 : 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: _infoBlue.withValues(alpha: 0.85), size: 13),
              const SizedBox(width: 7),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _infoBlue.withValues(alpha: isDark ? 0.85 : 0.9),
                      fontSize: 11,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: s.loginInfoPrefix),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: onRegisterTap,
                          child: Text(
                            s.loginInfoAction,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _infoBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: _infoBlue,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: s.loginInfoSuffix),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Login Button ─────────────────────────────────────────────────────────────

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.canSubmit,
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  final bool canSubmit;
  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: canSubmit ? 1.0 : 0.45,
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: (canSubmit && !isLoading) ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary,
            disabledForegroundColor: Colors.white,
            elevation: canSubmit ? 2 : 0,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
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
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    key: const ValueKey('label'),
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Register Chip ────────────────────────────────────────────────────────────

class _RegisterChip extends StatelessWidget {
  const _RegisterChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                S.of(context).registerLink,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
