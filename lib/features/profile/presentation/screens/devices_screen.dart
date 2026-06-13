import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/device_model.dart';
import '../../domain/providers/device_provider.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final devicesAsync = ref.watch(devicesProvider);

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
        title: Text(s.devicesTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: devicesAsync.when(
        loading: () => const AppLoading(),
        error: (_, _) => ErrorRetryWidget(
          message: s.noInternet,
          onRetry: () => ref.read(devicesProvider.notifier).refresh(),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.devices_other_rounded,
              title: s.devicesEmptyTitle,
              subtitle: s.devicesEmptyDesc,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _DeviceCard(
                device: devices[i],
                onRevoke: () => _confirmRevoke(context, ref, devices[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRevoke(
      BuildContext context, WidgetRef ref, DeviceModel device) async {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    HapticFeedback.selectionClick();
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                s.deviceRevokeTitle,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                device.isCurrent
                    ? s.deviceRevokeCurrentConfirm
                    : s.deviceRevokeConfirm,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 13.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
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
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(s.deviceRevoke,
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

    if (confirm != true || !context.mounted) return;

    final wasCurrent = device.isCurrent;
    final ok = await ref.read(devicesProvider.notifier).revoke(device.id);

    if (!context.mounted) return;

    if (ok) {
      HapticFeedback.lightImpact();
      // Joriy qurilma chiqarilsa — tizimdan chiqib login ekraniga o'tamiz.
      if (wasCurrent) {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(s.deviceRevokedMsg),
        ));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(s.deviceRevokeFailed),
        ));
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onRevoke;

  const _DeviceCard({required this.device, required this.onRevoke});

  IconData get _icon {
    switch (device.platform) {
      case 'ios':
      case 'macos':
        return Icons.phone_iphone_rounded;
      case 'android':
        return Icons.phone_android_rounded;
      case 'telegram':
        return Icons.send_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final name = (device.deviceName?.isNotEmpty == true)
        ? device.deviceName!
        : s.deviceUnknown;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: device.isCurrent
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (device.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.deviceCurrent,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle(s),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRevoke,
            icon: const Icon(Icons.logout_rounded, size: 20),
            color: AppColors.error,
            tooltip: s.deviceRevoke,
          ),
        ],
      ),
    );
  }

  String _subtitle(S s) {
    final parts = <String>[];
    if (device.appVersion?.isNotEmpty == true) {
      parts.add('v${device.appVersion}');
    }
    final last = device.lastActiveAt;
    if (last != null) {
      parts.add('${s.deviceLastActive}: ${_relative(last)}');
    }
    return parts.join(' · ');
  }

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd.MM.yyyy').format(dt);
  }
}
