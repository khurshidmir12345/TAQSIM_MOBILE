import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../l10n/translations.dart';
import '../providers/system_link_provider.dart';

/// Login va Register sahifalarida button tepasida ko'rsatiladigan
/// siyosat havolasi. Tugmaga bosish uchun birlashtirilgan minimal widget.
///
/// [isLogin] = true  → "Kirish orqali ..."
/// [isLogin] = false → "Ro'yxatdan o'tish orqali ..."
class PolicyLinksHint extends ConsumerWidget {
  const PolicyLinksHint({super.key, this.isLogin = true});

  final bool isLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final links = ref.watch(systemLinksProvider).asData?.value ?? [];

    final termsUrl  = _urlFor(links, 'terms');
    final privacyUrl = _urlFor(links, 'privacy');

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
            TextSpan(text: isLogin ? s.policyLoginPrefix : s.policyRegisterPrefix),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => _open(termsUrl),
                child: Text(s.policyTerms, style: linkStyle),
              ),
            ),
            TextSpan(text: s.policyAnd),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => _open(privacyUrl),
                child: Text(s.policyPrivacy, style: linkStyle),
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
      return (links.firstWhere((l) => l.type == type)).url as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
