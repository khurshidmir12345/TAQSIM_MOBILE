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
          _buildInfoCard(cs, s, user),
          const SizedBox(height: 16),
          _buildLinksSection(context, cs, s, user),
          const SizedBox(height: 32),
          _buildDangerZone(context, ref, cs, s),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs, S s, UserModel? user) {
    final linked = <String>[];
    if (user?.phone != null) linked.add(s.phoneNumber);
    if (user?.email != null) linked.add(s.email);
    if (user?.telegramUsername != null) linked.add(s.telegram);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linked.isEmpty
                      ? s.notLinked
                      : '${linked.length}/3 ${s.linked.toLowerCase()}',
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
        ],
      ),
    );
  }

  Widget _buildLinksSection(
      BuildContext context, ColorScheme cs, S s, UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          _ProfileLinkTile(
            icon: Icons.phone_outlined,
            title: s.phoneNumber,
            value: user?.phone,
            iconColor: AppColors.primary,
            onTap: () {},
          ),
          Divider(
              height: 1,
              indent: 72,
              color: cs.onSurface.withValues(alpha: 0.06)),
          _ProfileLinkTile(
            icon: Icons.email_outlined,
            title: s.email,
            value: user?.email,
            iconColor: AppColors.info,
            onTap: () {},
          ),
          Divider(
              height: 1,
              indent: 72,
              color: cs.onSurface.withValues(alpha: 0.06)),
          _ProfileLinkTile(
            icon: Icons.send_outlined,
            title: s.telegram,
            value: user?.telegramUsername != null
                ? '@${user!.telegramUsername}'
                : null,
            iconColor: const Color(0xFF2AABEE),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(
      BuildContext context, WidgetRef ref, ColorScheme cs, S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            s.deleteAccount.toUpperCase(),
            style: TextStyle(
              color: AppColors.error.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: AppColors.error.withValues(alpha: 0.12)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDeleteConfirm(context, ref, cs, s),
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
        ),
      ],
    );
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
                        child: Text(
                          s.cancel,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                        child: Text(
                          s.delete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

class _ProfileLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Color iconColor;
  final VoidCallback onTap;

  const _ProfileLinkTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final isLinked = value != null && value!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLinked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        s.linked,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
