import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/auth/domain/providers/auth_provider.dart';
import '../constants/app_spacing.dart';
import '../l10n/translations.dart';

/// Qaysi provider hozir kirish jarayonida ekanini bildiradi (faqat bosilgan
/// tugmada spinner ko'rsatish uchun).
enum _SocialProvider { apple, google }

/// Login va Register sahifalarida bir xil ishlatiladi.
///
/// "— yoki —" divider + ijtimoiy kirish:
///  - iOS/macOS: Apple Sign In (Guideline 4.8 majburiyati)
///  - Google Sign In (Android + iOS) — rasmiy brending bilan.
class SocialAuthSection extends ConsumerStatefulWidget {
  const SocialAuthSection({super.key, this.onAuthenticated});

  /// Muvaffaqiyatli kirgandan keyin chaqiriladi (router navigatsiya va shop
  /// yuklash uchun).
  final VoidCallback? onAuthenticated;

  @override
  ConsumerState<SocialAuthSection> createState() => _SocialAuthSectionState();
}

class _SocialAuthSectionState extends ConsumerState<SocialAuthSection> {
  _SocialProvider? _pending;

  bool get _isApplePlatform => Platform.isIOS || Platform.isMacOS;

  Future<void> _handleApple() async {
    if (_pending != null) return;
    HapticFeedback.lightImpact();
    setState(() => _pending = _SocialProvider.apple);

    final s = S.of(context);
    final ok = await ref.read(authProvider.notifier).signInWithApple();
    if (!mounted) return;
    setState(() => _pending = null);

    if (ok) {
      widget.onAuthenticated?.call();
      return;
    }
    final error = ref.read(authProvider).error;
    if (error != null && error.isNotEmpty && error != 'apple_unsupported_platform') {
      _showError(_withDebugDetail(s.appleSignInFailed, error));
    }
  }

  Future<void> _handleGoogle() async {
    if (_pending != null) return;
    HapticFeedback.lightImpact();
    setState(() => _pending = _SocialProvider.google);

    final s = S.of(context);
    final ok = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _pending = null);

    if (ok) {
      widget.onAuthenticated?.call();
      return;
    }
    final error = ref.read(authProvider).error;
    if (error != null &&
        error.isNotEmpty &&
        error != 'google_unsupported_platform') {
      _showError(_withDebugDetail(s.googleSignInFailed, error));
    }
  }

  /// Debug build'da xatoning texnik tafsilotini xabarga qo'shadi — diagnostika
  /// uchun. Release'da faqat foydalanuvchiga tushunarli xabar ko'rinadi.
  String _withDebugDetail(String message, String error) {
    if (kDebugMode) return '$message\n[$error]';
    return message;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final busy = _pending != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  s.orDivider,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_isApplePlatform) ...[
          _AppleButton(
            isLoading: _pending == _SocialProvider.apple,
            enabled: !busy,
            onTap: _handleApple,
          ),
          const SizedBox(height: 10),
        ],
        _GoogleButton(
          label: s.signInWithGoogle,
          isLoading: _pending == _SocialProvider.google,
          enabled: !busy,
          onTap: _handleGoogle,
        ),
      ],
    );
  }
}

/// Apple guidelinega muvofiq qora rangli, oq Apple logosi va matnli ko'rinish.
class _AppleButton extends StatelessWidget {
  const _AppleButton({
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;
    final s = S.of(context);

    return Opacity(
      opacity: enabled || isLoading ? 1 : 0.6,
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apple, color: fg, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          s.signInWithApple,
                          style: TextStyle(
                            color: fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google brending qoidalariga mos tugma:
///  - Light: oq fon (#FFFFFF), kulrang chegara, to'q matn.
///  - Dark: to'q fon (#131314), och matn.
///  - Markazda rasmiy 4-rangli "G" logosi.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF131314) : Colors.white;
    final fg = isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    final border =
        isDark ? const Color(0xFF8E918F) : const Color(0xFFDADCE0);

    return Opacity(
      opacity: enabled || isLoading ? 1 : 0.6,
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                border: Border.all(color: border),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.string(
                            _googleGLogoSvg,
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: TextStyle(
                              color: fg,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
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

/// Rasmiy Google "G" logosi (4-rangli), brending qoidalariga mos.
const String _googleGLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
<path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';
