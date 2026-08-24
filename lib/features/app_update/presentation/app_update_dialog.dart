import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/l10n/translations.dart';
import '../domain/models/app_update_info.dart';

/// "Yangilanish bor — yangilaysizmi?" kartasi.
///
/// Navigator route emas, oddiy widget: asosiy sahifa ichida chiziladi
/// (`StartupPromptOverlay`). Shu sababli sahifa almashishi yoki router
/// yangilanishi uni yopa olmaydi — foydalanuvchi tugma bosmaguncha turadi.
///
/// Majburiy emas: "Keyinroq" bosib ishini davom ettirish mumkin. Modalkani
/// butunlay o'chirish serverdagi `APP_UPDATE_ENABLED` orqali.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.info,
    required this.onDismiss,
  });

  final AppUpdateInfo info;

  /// Tugmalardan biri bosilganda chaqiriladi.
  final VoidCallback onDismiss;

  Future<void> _openStore() async {
    final url = info.storeUrl;
    final uri = url == null ? null : Uri.tryParse(url);

    if (uri != null) {
      // Do'kon ochilmasa ham modalka yopiladi — foydalanuvchi tiqilib
      // qolmasligi kerak.
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Do'kon ilovasi yo'q yoki manzil noto'g'ri — jim o'tamiz.
      }
    }

    onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final version = info.latestVersion;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.system_update_rounded,
          color: AppColors.primary,
          size: 26,
        ),
      ),
      title: Text(
        s.updateAvailableTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        version != null
            ? s.updateAvailableMessageVersion(version)
            : s.updateAvailableMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: onDismiss, child: Text(s.updateLater)),
        if (info.storeUrl != null)
          FilledButton(onPressed: _openStore, child: Text(s.updateNow)),
      ],
    );
  }
}
