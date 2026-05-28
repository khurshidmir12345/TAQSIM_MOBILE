import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/providers/auth_provider.dart';
import '../constants/app_spacing.dart';
import '../l10n/translations.dart';

/// Login va Register sahifalarida bir xil ishlatiladi.
///
/// "— yoki —" divider + ijtimoiy kirish:
///  - iOS/macOS: Apple Sign In (Guideline 4.8 majburiyati)
///  - Telegram
///  - Google (hozircha "tez orada")
class SocialAuthSection extends ConsumerWidget {
  const SocialAuthSection({super.key, this.onAuthenticated});

  /// Apple orqali muvaffaqiyatli kirgandan keyin chaqiriladi (router navigatsiya
  /// va shop yuklash uchun).
  final VoidCallback? onAuthenticated;

  bool get _isApplePlatform => Platform.isIOS || Platform.isMacOS;

  void _showComingSoon(BuildContext context, String name) {
    final s = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.socialComingSoon(name)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleApple(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final ok = await ref.read(authProvider.notifier).signInWithApple();
    if (!context.mounted) return;
    if (ok) {
      onAuthenticated?.call();
    } else {
      final error = ref.read(authProvider).error;
      if (error != null && error.isNotEmpty && error != 'apple_unsupported_platform') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.appleSignInFailed),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
    final isLoading = ref.watch(authProvider.select((a) => a.isLoading));

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
            isLoading: isLoading,
            onTap: () => _handleApple(context, ref),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _SocialBtn(
                icon: Icons.telegram_rounded,
                iconColor: const Color(0xFF229ED9),
                label: 'Telegram',
                borderColor: borderColor,
                onTap: () => context.go('/telegram-auth'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SocialBtn(
                icon: null,
                iconColor: const Color(0xFFDB4437),
                label: 'Google',
                borderColor: borderColor,
                onTap: () => _showComingSoon(context, 'Google'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Apple guidelinega muvofiq qora rangli, oq Apple logosi va "Sign in with
/// Apple" matnli rasmiy ko'rinish.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;
    final s = S.of(context);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: InkWell(
          onTap: isLoading ? null : onTap,
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
    );
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.borderColor,
    required this.onTap,
  });

  /// null → Google "G" styled icon
  final IconData? icon;
  final Color iconColor;
  final String label;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconWidget(icon: icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconWidget extends StatelessWidget {
  const _IconWidget({required this.icon, required this.color});

  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Icon(icon, color: color, size: 20);
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.8),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
