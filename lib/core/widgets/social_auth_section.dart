import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_spacing.dart';
import '../l10n/translations.dart';

/// Login va Register sahifalarida bir xil ishlatiladi.
/// "— yoki —" divider + Telegram / Google orqali kirish.
class SocialAuthSection extends StatelessWidget {
  const SocialAuthSection({super.key});

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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outline.withValues(alpha: 0.35);

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
        const SizedBox(height: 4),
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
