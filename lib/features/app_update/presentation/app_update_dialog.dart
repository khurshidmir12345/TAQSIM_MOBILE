import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/l10n/translations.dart';
import '../domain/models/app_update_info.dart';

/// "Yangilanish bor — yangilaysizmi?" modalkasi.
///
/// Modalka o'z-o'zidan yopilmaydi: fon bosilsa ham, "orqaga" bosilsa ham
/// joyida qoladi. Faqat ikkita tugmadan biri uni yopadi — "Keyinroq" yopadi,
/// "Yangilash" do'konni ochib yopadi.
///
/// Modalkani butunlay o'chirish serverdagi `APP_UPDATE_ENABLED` orqali.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.info});

  final AppUpdateInfo info;

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      // Fonni bosish modalkani yopmaydi — foydalanuvchi tanlov qilishi kerak.
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(info: info),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final url = info.storeUrl;
    if (url == null) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final navigator = Navigator.of(context);

    // Do'kon ochilmasa ham modalka yopiladi — foydalanuvchi tiqilib
    // qolmasligi kerak.
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Do'kon ilovasi yo'q yoki manzil noto'g'ri — jim o'tamiz.
    }

    if (navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final version = info.latestVersion;

    // Android "orqaga" tugmasi ham modalkani yopmasin.
    return PopScope(
      canPop: false,
      child: AlertDialog(
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.updateLater),
          ),
          if (info.storeUrl != null)
            FilledButton(
              onPressed: () => _openStore(context),
              child: Text(s.updateNow),
            ),
        ],
      ),
    );
  }
}
