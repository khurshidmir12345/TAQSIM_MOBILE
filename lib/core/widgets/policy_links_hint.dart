import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../l10n/translations.dart';
import '../providers/system_link_provider.dart';

/// Login va Register sahifalarida button tepasida ko'rsatiladigan
/// siyosat havolasi. URL'lar backend (`system_links`) dan olinadi.
///
/// [isLogin] = true  → "Kirish orqali ..."
/// [isLogin] = false → "Ro'yxatdan o'tish orqali ..."
class PolicyLinksHint extends ConsumerWidget {
  const PolicyLinksHint({super.key, this.isLogin = true});

  final bool isLogin;

  static const _fallbackTermsUrl = 'https://taqseem.uz/terms';
  static const _fallbackPrivacyUrl = 'https://taqseem.uz/privacy';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final linksAsync = ref.watch(systemLinksProvider);
    final links = linksAsync.asData?.value ?? const [];

    final termsUrl = _urlFor(links, 'terms') ?? _fallbackTermsUrl;
    final privacyUrl = _urlFor(links, 'privacy') ?? _fallbackPrivacyUrl;

    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textHint,
      fontSize: 11,
      height: 1.5,
    );
    final linkStyle = baseStyle?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.textSecondary,
    );

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(
              text: isLogin ? s.policyLoginPrefix : s.policyRegisterPrefix,
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _LinkText(
                label: s.policyTerms,
                style: linkStyle,
                onTap: () => _open(context, termsUrl),
              ),
            ),
            TextSpan(text: s.policyAnd),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _LinkText(
                label: s.policyPrivacy,
                style: linkStyle,
                onTap: () => _open(context, privacyUrl),
              ),
            ),
            TextSpan(text: s.policySuffix),
          ],
        ),
      ),
    );
  }

  String? _urlFor(List links, String type) {
    try {
      final url = (links.firstWhere((l) => l.type == type)).url as String?;
      return (url != null && url.trim().isNotEmpty) ? url : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    try {
      final launched = await launchUrl(
        uri,
      );
      if (launched) return;
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(url),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Tap hududini kengaytirgan va visual feedback beradigan link widget.
class _LinkText extends StatelessWidget {
  const _LinkText({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(label, style: style),
      ),
    );
  }
}
