import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Profile information screen.
///
/// Goals (UX):
/// - No "complete your profile" progress — each login method is optional.
/// - All three login methods are visible so the user is aware of them,
///   but filled ones look solid/active and unfilled ones look soft/dormant.
///   There is no loud "LINK" CTA that implies linking is required.
/// - Delete account is a small action in the app bar instead of a big
///   destructive card.
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
          s.profileInfo,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          _DeleteMenuButton(
            onDelete: () => _showDeleteConfirm(context, ref, cs, s),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 32),
        children: [
          _SectionLabel(text: s.personalInfo),
          const SizedBox(height: 8),
          _PersonalInfoCard(user: user),
          const SizedBox(height: 24),
          _SectionLabel(text: s.loginMethods),
          const SizedBox(height: 8),
          _LoginMethodsCard(user: user),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, WidgetRef ref, ColorScheme cs, S s) {
    HapticFeedback.mediumImpact();
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

// ─── AppBar Delete Menu ──────────────────────────────────────────────────────

class _DeleteMenuButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteMenuButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: PopupMenuButton<String>(
        tooltip: '',
        offset: const Offset(0, 44),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: cs.surface,
        elevation: 8,
        icon: Icon(
          Icons.more_vert_rounded,
          size: 22,
          color: cs.onSurface.withValues(alpha: 0.75),
        ),
        onSelected: (v) {
          if (v == 'delete') onDelete();
        },
        itemBuilder: (ctx) => [
          PopupMenuItem<String>(
            value: 'delete',
            height: 44,
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Text(
                  s.deleteAccount,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

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

// ─── Personal info (name) ────────────────────────────────────────────────────

class _PersonalInfoCard extends ConsumerWidget {
  final UserModel? user;
  const _PersonalInfoCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return _Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            label: s.fullNameHint,
            value: user?.name,
            onTap: () => _editName(context, ref, s),
          ),
          _Divider(cs: cs),
          _InfoRow(
            icon: Icons.email_outlined,
            iconColor: AppColors.info,
            label: s.email,
            value: user?.email,
            onTap: () => _editEmail(context, ref, s),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, S s) async {
    final result = await _EditFieldSheet.show(
      context: context,
      title: s.editName,
      label: s.fullNameHint,
      initialValue: user?.name ?? '',
      icon: Icons.person_outline_rounded,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      validator: (v) => v.trim().isEmpty ? s.nameRequired : null,
    );
    if (result == null || !context.mounted) return;
    final ok =
        await ref.read(authProvider.notifier).updateProfile(name: result);
    if (!context.mounted) return;
    _showResult(context, ref, ok, s);
  }

  Future<void> _editEmail(BuildContext context, WidgetRef ref, S s) async {
    final result = await _EditFieldSheet.show(
      context: context,
      title: s.editEmail,
      label: s.email,
      initialValue: user?.email ?? '',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v.isEmpty) return null;
        final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        return pattern.hasMatch(v.trim()) ? null : s.invalidEmail;
      },
    );
    if (result == null || !context.mounted) return;
    final ok =
        await ref.read(authProvider.notifier).updateProfile(email: result);
    if (!context.mounted) return;
    _showResult(context, ref, ok, s);
  }

  void _showResult(BuildContext context, WidgetRef ref, bool ok, S s) {
    final msg = ok
        ? s.profileUpdated
        : (ref.read(authProvider).error ?? s.noData);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? null : AppColors.error,
          content: Text(msg),
        ),
      );
  }
}

// ─── Login methods ───────────────────────────────────────────────────────────

class _LoginMethodsCard extends StatelessWidget {
  final UserModel? user;
  const _LoginMethodsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    final hasPhone = user?.phone?.isNotEmpty == true;
    final hasEmail = user?.email?.isNotEmpty == true;
    final hasTelegram = (user?.telegramUsername?.isNotEmpty == true) ||
        (user?.telegramChatId != null);

    final telegramValue = user?.telegramUsername?.isNotEmpty == true
        ? '@${user!.telegramUsername}'
        : (user?.telegramChatId != null
            ? user!.telegramChatId!.toString()
            : null);

    return _Card(
      child: Column(
        children: [
          _MethodRow(
            icon: Icons.phone_rounded,
            brandColor: AppColors.primary,
            label: s.phoneNumber,
            value: user?.phone,
            active: hasPhone,
            readOnly: true,
          ),
          _Divider(cs: cs),
          _MethodRow(
            icon: Icons.alternate_email_rounded,
            brandColor: AppColors.info,
            label: s.email,
            value: user?.email,
            active: hasEmail,
            readOnly: true,
          ),
          _Divider(cs: cs),
          _MethodRow(
            icon: Icons.send_rounded,
            brandColor: const Color(0xFF2AABEE),
            label: s.telegram,
            value: telegramValue,
            active: hasTelegram,
            readOnly: true,
          ),
        ],
      ),
    );
  }
}

/// Visually-weighted row for a login method.
///
/// - When active: icon tile is fully colored, label solid, value shown with
///   a small confirmation dot on the right.
/// - When inactive: everything dims to ~40% so the row is unmistakably
///   dormant but still legible; there is intentionally no "LINK" CTA.
class _MethodRow extends StatelessWidget {
  final IconData icon;
  final Color brandColor;
  final String label;
  final String? value;
  final bool active;
  final bool readOnly;

  const _MethodRow({
    required this.icon,
    required this.brandColor,
    required this.label,
    required this.value,
    required this.active,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseText = cs.onSurface;

    final labelColor = active
        ? baseText.withValues(alpha: 0.9)
        : baseText.withValues(alpha: 0.38);
    final valueColor = active
        ? baseText.withValues(alpha: 0.55)
        : baseText.withValues(alpha: 0.32);
    final tileBg = active
        ? brandColor.withValues(alpha: 0.12)
        : cs.onSurface.withValues(alpha: 0.05);
    final iconColor = active
        ? brandColor
        : cs.onSurface.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  active ? value! : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: brandColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Generic info row (editable) ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.9),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValue ? value! : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: hasValue
                            ? cs.onSurface.withValues(alpha: 0.55)
                            : cs.onSurface.withValues(alpha: 0.35),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared primitives ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme cs;
  const _Divider({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68,
      color: cs.onSurface.withValues(alpha: 0.06),
    );
  }
}

// ─── Edit field bottom sheet ─────────────────────────────────────────────────

class _EditFieldSheet extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String value) validator;

  const _EditFieldSheet({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.keyboardType,
    required this.textCapitalization,
    required this.validator,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String label,
    required String initialValue,
    required IconData icon,
    required TextInputType keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required String? Function(String value) validator,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _EditFieldSheet(
          title: title,
          label: label,
          initialValue: initialValue,
          icon: icon,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
        ),
      ),
    );
  }

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _ctrl.text.trim();
    final err = widget.validator(raw);
    if (err != null) {
      setState(() => _error = err);
      HapticFeedback.heavyImpact();
      return;
    }
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(widget.icon,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  labelText: widget.label,
                  errorText: _error,
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                      onTap: _submit,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.actionSave,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
