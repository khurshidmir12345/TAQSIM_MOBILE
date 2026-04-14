import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _fmtBalance(String? raw) {
    final v = double.tryParse(raw ?? '0') ?? 0;
    return NumberFormat('#,##0', 'uz').format(v);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final pad = Responsive.horizontalPadding(context);
    final s = S.of(context);
    final currentLocale = ref.watch(localeProvider).value ?? AppLocale.uz;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: user,
              onPickAvatar: () => _pickAvatar(context, ref),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BalanceCard(
                  balance: _fmtBalance(user?.balance),
                  isDark: isDark,
                  onTopUp: () => context.push('/top-up'),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: s.general),
                const SizedBox(height: 8),
                _MenuCard(children: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    title: s.profileInfo,
                    subtitle: s.profileInfoDesc,
                    iconBg: AppColors.info.withValues(alpha: 0.1),
                    iconColor: AppColors.info,
                    onTap: () => context.push('/profile-info'),
                  ),
                  _MenuItem(
                    icon: Icons.storefront_outlined,
                    title: s.bakeries,
                    subtitle: s.manageAndSwitch,
                    iconBg: cs.primary.withValues(alpha: 0.1),
                    iconColor: cs.primary,
                    onTap: () => context.go('/shop-select'),
                  ),
                ]),
                const SizedBox(height: 20),
                _SectionTitle(title: s.settings),
                const SizedBox(height: 8),
                _MenuCard(children: [
                  _DarkModeItem(
                    isDark: themeMode == ThemeMode.dark,
                    onChanged: (_) =>
                        ref.read(themeModeProvider.notifier).toggle(),
                  ),
                  _LanguageItem(
                    locale: currentLocale,
                    onTap: () =>
                        _showLanguagePicker(context, ref, currentLocale),
                  ),
                ]),
                const SizedBox(height: 20),
                _SectionTitle(title: s.aboutApp),
                const SizedBox(height: 8),
                _MenuCard(children: [
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    title: s.aboutApp,
                    subtitle: '${s.version} 1.0.0',
                    iconBg: cs.primary.withValues(alpha: 0.1),
                    iconColor: cs.primary,
                    onTap: () => _showAboutSheet(context, cs, s),
                  ),
                  _MenuItem(
                    icon: Icons.shield_outlined,
                    title: s.privacyPolicy,
                    subtitle: s.privacyPolicyDesc,
                    iconBg: AppColors.warning.withValues(alpha: 0.1),
                    iconColor: AppColors.warning,
                    onTap: () => _launchUrl('https://www.taqseem.uz/privacy'),
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    title: s.termsOfService,
                    subtitle: s.termsOfServiceDesc,
                    iconBg: AppColors.info.withValues(alpha: 0.1),
                    iconColor: AppColors.info,
                    onTap: () => _launchUrl('https://www.taqseem.uz/terms'),
                  ),
                ]),
                const SizedBox(height: 20),
                _SectionTitle(
                  title: s.account,
                  color: AppColors.error.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                _MenuCard(children: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    title: s.logout,
                    subtitle: s.logoutDesc,
                    iconBg: AppColors.error.withValues(alpha: 0.08),
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                    showChevron: false,
                    onTap: () => _showLogoutConfirm(context, ref, cs, s),
                  ),
                ]),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;
    if (context.mounted) {
      final success =
          await ref.read(authProvider.notifier).uploadAvatar(image.path);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ref.read(authProvider).error ?? S.of(context).noData),
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLogoutConfirm(
      BuildContext context, WidgetRef ref, ColorScheme cs, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                s.logoutConfirm,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(s.cancel,
                            style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(s.logout,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context, ColorScheme cs, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'TAQSEEM',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.version} 1.0.0',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  s.aboutAppDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _AboutTile(
                    icon: Icons.code_rounded,
                    label: s.developer,
                    value: 'TAQSEEM Team',
                    cs: cs,
                  ),
                  const SizedBox(width: 10),
                  _AboutTile(
                    icon: Icons.language_rounded,
                    label: s.website,
                    value: 'taqseem.uz',
                    cs: cs,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _AboutTile(
                    icon: Icons.send_rounded,
                    label: s.telegram,
                    value: '@taqseem_uz',
                    cs: cs,
                  ),
                  const SizedBox(width: 10),
                  _AboutTile(
                    icon: Icons.phone_rounded,
                    label: s.support,
                    value: '+998 90 123 45 67',
                    cs: cs,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                s.madeInUzbekistan,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, WidgetRef ref, AppLocale current) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.of(context).language,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            ...AppLocale.values.map((locale) {
              final isSelected = locale == current;
              return ListTile(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(locale);
                  Navigator.pop(ctx);
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.1)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.language_rounded,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.4),
                      size: 20),
                ),
                title: Text(locale.displayName,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: cs.onSurface)),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        color: cs.primary, size: 22)
                    : null,
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onPickAvatar;

  const _ProfileHeader({required this.user, required this.onPickAvatar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name =
        (user?.name?.isNotEmpty == true) ? user!.name! : S.of(context).defaultUser;
    final initial = name[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? AppColors.cardGradientDark
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              GestureDetector(
                onTap: onPickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: user?.avatarUrl != null &&
                              user!.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user!.avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => _Initial(initial),
                              errorWidget: (_, _, _) => _Initial(initial),
                            )
                          : _Initial(initial),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.camera_alt_rounded,
                            color: AppColors.primary, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_hasContact) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: _buildChips(cs),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasContact =>
      (user?.phone?.isNotEmpty == true) ||
      (user?.email?.isNotEmpty == true) ||
      (user?.telegramUsername?.isNotEmpty == true);

  List<Widget> _buildChips(ColorScheme cs) {
    final chips = <Widget>[];
    if (user?.phone?.isNotEmpty == true) {
      chips.add(_HeaderChip(Icons.phone_outlined, user!.phone!));
    }
    if (user?.email?.isNotEmpty == true) {
      chips.add(_HeaderChip(Icons.email_outlined, user!.email!));
    }
    if (user?.telegramUsername?.isNotEmpty == true) {
      chips.add(_HeaderChip(Icons.send_outlined, '@${user!.telegramUsername}'));
    }
    return chips;
  }
}

class _Initial extends StatelessWidget {
  final String letter;
  const _Initial(this.letter);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(letter,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeaderChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Balance Card ────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final String balance;
  final bool isDark;
  final VoidCallback onTopUp;

  const _BalanceCard({
    required this.balance,
    required this.isDark,
    required this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.cardGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.balance,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    '$balance UZS',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onTopUp,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(s.topUp,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionTitle({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color ?? cs.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Menu Card ───────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

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
        children: List.generate(children.length, (i) {
          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 68,
                  color: cs.onSurface.withValues(alpha: 0.06),
                ),
              children[i],
            ],
          );
        }),
      ),
    );
  }
}

// ─── Menu Item ───────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: titleColor ?? cs.onSurface)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: cs.onSurface.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dark Mode Item ──────────────────────────────────────────────────────────

class _DarkModeItem extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _DarkModeItem({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: cs.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.darkMode,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                Text(isDark ? s.enabled : s.disabled,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            onChanged: onChanged,
            activeTrackColor: cs.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Language Item ────────────────────────────────────────────────────────────

class _LanguageItem extends StatelessWidget {
  final AppLocale locale;
  final VoidCallback onTap;
  const _LanguageItem({required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.language_rounded,
                    color: cs.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.language,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    Text(locale.displayName,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurface.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── About Tile ──────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _AboutTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
