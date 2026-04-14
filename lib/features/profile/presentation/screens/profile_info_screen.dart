import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class ProfileInfoScreen extends ConsumerWidget {
  const ProfileInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);
    final s = S.of(context);

    final linkedCount = _countLinked(user);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileInfo),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
        children: [
          _StatusBanner(linkedCount: linkedCount, s: s, cs: cs),
          const SizedBox(height: 20),
          _SectionLabel(text: s.profileInfo),
          const SizedBox(height: 8),
          _LinksCard(user: user, cs: cs, s: s),
          const SizedBox(height: 28),
          _SectionLabel(
            text: s.deleteAccount,
            color: AppColors.error.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          _DeleteAccountCard(
            onTap: () => _showDeleteConfirm(context, ref, cs, s),
            cs: cs,
            s: s,
          ),
        ],
      ),
    );
  }

  int _countLinked(UserModel? user) {
    var count = 0;
    if (user?.phone != null && user!.phone!.isNotEmpty) count++;
    if (user?.email != null && user!.email!.isNotEmpty) count++;
    if (user?.telegramUsername != null && user!.telegramUsername!.isNotEmpty) {
      count++;
    }
    return count;
  }

  void _showDeleteConfirm(
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
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                s.deleteAccountConfirm,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  s.deleteAccountDesc,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                        final success = await ref
                            .read(authProvider.notifier)
                            .deleteAccount();
                        if (success && context.mounted) {
                          context.go('/login');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(s.delete,
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
}

// ─── Status Banner ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final int linkedCount;
  final S s;
  final ColorScheme cs;

  const _StatusBanner({
    required this.linkedCount,
    required this.s,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = linkedCount == 3;
    final color = isComplete ? AppColors.success : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isComplete
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$linkedCount/3 ${s.linked.toLowerCase()}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.profileInfoDesc,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                '$linkedCount',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const _SectionLabel({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
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

// ─── Links Card ──────────────────────────────────────────────────────────────

class _LinksCard extends StatelessWidget {
  final UserModel? user;
  final ColorScheme cs;
  final S s;

  const _LinksCard({required this.user, required this.cs, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _LinkTile(
            icon: Icons.phone_outlined,
            title: s.phoneNumber,
            value: user?.phone,
            iconColor: AppColors.primary,
            s: s,
          ),
          _divider,
          _LinkTile(
            icon: Icons.email_outlined,
            title: s.email,
            value: user?.email,
            iconColor: AppColors.info,
            s: s,
          ),
          _divider,
          _LinkTile(
            icon: Icons.send_outlined,
            title: s.telegram,
            value: user?.telegramUsername != null
                ? '@${user!.telegramUsername}'
                : null,
            iconColor: const Color(0xFF2AABEE),
            s: s,
          ),
        ],
      ),
    );
  }

  Widget get _divider => Divider(
        height: 1,
        indent: 68,
        color: cs.onSurface.withValues(alpha: 0.06),
      );
}

// ─── Link Tile ───────────────────────────────────────────────────────────────

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Color iconColor;
  final S s;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLinked = value != null && value!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
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
                        color: cs.onSurface)),
                const SizedBox(height: 1),
                Text(
                  isLinked ? value! : s.notLinked,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLinked
                        ? cs.onSurface.withValues(alpha: 0.5)
                        : AppColors.error.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (isLinked)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    s.linked,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s.link,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Delete Account Card ─────────────────────────────────────────────────────

class _DeleteAccountCard extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  final S s;

  const _DeleteAccountCard({
    required this.onTap,
    required this.cs,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.deleteAccount,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.deleteAccountDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.error.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
