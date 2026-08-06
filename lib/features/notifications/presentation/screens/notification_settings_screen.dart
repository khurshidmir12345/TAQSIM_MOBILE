import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../domain/providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);
    final async = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

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
          s.notificationsSettings,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (_, _) => ErrorRetryWidget(
          message: s.noInternet,
          onRetry: () => ref.invalidate(notificationPreferencesProvider),
        ),
        data: (prefs) {
          // Umumiy tugma o'chirilganda qolganlari mantiqan ta'sir qilmaydi.
          final subEnabled = prefs.enabled;

          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
            children: [
              _SwitchTile(
                title: s.notifPrefAll,
                subtitle: s.notifPrefAllDesc,
                value: prefs.enabled,
                onChanged: (v) => notifier.setValue('enabled', v),
              ),
              const SizedBox(height: 20),
              Opacity(
                opacity: subEnabled ? 1 : 0.45,
                child: IgnorePointer(
                  ignoring: !subEnabled,
                  child: Column(
                    children: [
                      _SwitchTile(
                        title: s.notifPrefDailyGreeting,
                        subtitle: s.notifPrefDailyGreetingDesc,
                        value: prefs.dailyGreeting,
                        onChanged: (v) =>
                            notifier.setValue('daily_greeting', v),
                      ),
                      const SizedBox(height: 10),
                      _SwitchTile(
                        title: s.notifPrefOrderReminder,
                        subtitle: s.notifPrefOrderReminderDesc,
                        value: prefs.orderReminder,
                        onChanged: (v) =>
                            notifier.setValue('order_reminder', v),
                      ),
                      const SizedBox(height: 10),
                      _SwitchTile(
                        title: s.notifPrefEmployeeAdded,
                        subtitle: s.notifPrefEmployeeAddedDesc,
                        value: prefs.employeeAdded,
                        onChanged: (v) =>
                            notifier.setValue('employee_added', v),
                      ),
                      const SizedBox(height: 10),
                      _SwitchTile(
                        title: s.notifPrefSystem,
                        subtitle: s.notifPrefSystemDesc,
                        value: prefs.system,
                        onChanged: (v) => notifier.setValue('system', v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.55)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.notifPrefsNote,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
