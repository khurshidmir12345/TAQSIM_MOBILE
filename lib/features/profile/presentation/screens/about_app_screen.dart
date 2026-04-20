import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';

/// Dedicated About screen replacing the earlier modal sheet.
///
/// Scope:
/// - Hero with brand, tagline, version.
/// - Short "why" paragraph.
/// - Feature grid.
/// - Contact cards (Telegram channel, Instagram, Support bot, Website)
///   each opening the corresponding deep link / URL.
/// - Legal links (Privacy Policy, Terms of Service).
/// - "Made in Uzbekistan" footer.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _appVersion = '1.0.0';

  static const _tgChannel = 'taqseem_rasmiy';
  static const _instagram = 'taqseem.uz';
  static const _supportBot = 'taqseem_support_bot';
  static const _website = 'https://taqseem.uz';
  static const _privacyUrl = 'https://www.taqseem.uz/privacy';
  static const _termsUrl = 'https://www.taqseem.uz/terms';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: Text(
          s.aboutApp,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 8, pad, 32),
        children: [
          _HeroBlock(
            version: _appVersion,
            tagline: s.aboutTagline,
          ),
          const SizedBox(height: 24),
          _SectionTitle(text: s.aboutWhyTitle),
          const SizedBox(height: 8),
          _WhyCard(body: s.aboutWhyBody),
          const SizedBox(height: 24),
          _SectionTitle(text: s.aboutFeaturesTitle),
          const SizedBox(height: 8),
          _FeaturesGrid(s: s),
          const SizedBox(height: 24),
          _SectionTitle(text: s.aboutContactTitle),
          const SizedBox(height: 8),
          _ContactsCard(
            items: [
              _ContactItem(
                icon: Icons.send_rounded,
                brand: const Color(0xFF2AABEE),
                label: s.aboutTelegramChannel,
                value: '@$_tgChannel',
                onTap: () => _openTelegram(_tgChannel),
              ),
              _ContactItem(
                icon: Icons.camera_alt_rounded,
                brand: const Color(0xFFE4405F),
                label: s.aboutInstagram,
                value: '@$_instagram',
                onTap: () =>
                    _openUrl('https://instagram.com/$_instagram'),
              ),
              _ContactItem(
                icon: Icons.support_agent_rounded,
                brand: AppColors.success,
                label: s.aboutSupport,
                value: '@$_supportBot',
                onTap: () => _openTelegram(_supportBot),
              ),
              _ContactItem(
                icon: Icons.language_rounded,
                brand: AppColors.primary,
                label: s.aboutWebsite,
                value: 'taqseem.uz',
                onTap: () => _openUrl(_website),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _LegalRow(
            onPrivacy: () => _openUrl(_privacyUrl),
            onTerms: () => _openUrl(_termsUrl),
            privacyLabel: s.privacyPolicy,
            termsLabel: s.termsOfService,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              s.madeInUzbekistan,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.35),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${s.version} $_appVersion',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.28),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── URL helpers ────────────────────────────────────────────────────────────

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTelegram(String username) async {
    final tgUri = Uri.parse('tg://resolve?domain=$username');
    if (await canLaunchUrl(tgUri)) {
      await launchUrl(tgUri);
      return;
    }
    await _openUrl('https://t.me/$username');
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroBlock extends StatelessWidget {
  final String version;
  final String tagline;
  const _HeroBlock({required this.version, required this.tagline});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.calculate_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'TAQSEEM',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.55),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'v$version',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.42),
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Why card ────────────────────────────────────────────────────────────────

class _WhyCard extends StatelessWidget {
  final String body;
  const _WhyCard({required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        body,
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.72),
          fontSize: 13.5,
          height: 1.55,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Features ────────────────────────────────────────────────────────────────

class _FeaturesGrid extends StatelessWidget {
  final S s;
  const _FeaturesGrid({required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final features = <_Feature>[
      _Feature(
          icon: Icons.factory_rounded,
          color: AppColors.primary,
          title: s.featProductionTitle,
          desc: s.featProductionDesc),
      _Feature(
          icon: Icons.receipt_long_rounded,
          color: AppColors.warning,
          title: s.featExpensesTitle,
          desc: s.featExpensesDesc),
      _Feature(
          icon: Icons.undo_rounded,
          color: AppColors.error,
          title: s.featReturnsTitle,
          desc: s.featReturnsDesc),
      _Feature(
          icon: Icons.bar_chart_rounded,
          color: AppColors.info,
          title: s.featReportsTitle,
          desc: s.featReportsDesc),
      _Feature(
          icon: Icons.storefront_rounded,
          color: AppColors.primary,
          title: s.featMultiShopTitle,
          desc: s.featMultiShopDesc),
      _Feature(
          icon: Icons.menu_book_rounded,
          color: AppColors.success,
          title: s.featRecipesTitle,
          desc: s.featRecipesDesc),
      _Feature(
          icon: Icons.language_rounded,
          color: AppColors.info,
          title: s.featMultiLangTitle,
          desc: s.featMultiLangDesc),
      _Feature(
          icon: Icons.dark_mode_rounded,
          color: cs.onSurface.withValues(alpha: 0.6),
          title: s.featDarkModeTitle,
          desc: s.featDarkModeDesc),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: List.generate(features.length, (i) {
          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 66,
                  color: cs.onSurface.withValues(alpha: 0.06),
                ),
              _FeatureRow(feature: features[i]),
            ],
          );
        }),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.desc,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.35,
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

// ─── Contacts ────────────────────────────────────────────────────────────────

class _ContactItem {
  final IconData icon;
  final Color brand;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ContactItem({
    required this.icon,
    required this.brand,
    required this.label,
    required this.value,
    required this.onTap,
  });
}

class _ContactsCard extends StatelessWidget {
  final List<_ContactItem> items;
  const _ContactsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 66,
                  color: cs.onSurface.withValues(alpha: 0.06),
                ),
              _ContactRow(item: items[i]),
            ],
          );
        }),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final _ContactItem item;
  const _ContactRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.brand, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Legal row ───────────────────────────────────────────────────────────────

class _LegalRow extends StatelessWidget {
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final String privacyLabel;
  final String termsLabel;

  const _LegalRow({
    required this.onPrivacy,
    required this.onTerms,
    required this.privacyLabel,
    required this.termsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget pill(String label, VoidCallback onTap) => Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: cs.outline.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );

    return Row(
      children: [
        pill(privacyLabel, onPrivacy),
        const SizedBox(width: 10),
        pill(termsLabel, onTerms),
      ],
    );
  }
}
