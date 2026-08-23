import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/l10n/translations.dart';

/// "Telegramni ulang" modalkasi.
///
/// Maqsadi — aloqa kanali: bildirishnomalar va qo'llab-quvvatlash Telegram
/// orqali boradi. Modalka ataylab shu haqda gapiradi, boshqa hech narsa
/// haqida emas.
///
/// Foydalanuvchi "Keyinroq" bosib ishini davom ettira oladi — bu majburiy
/// qadam emas.
class TelegramLinkDialog extends StatelessWidget {
  const TelegramLinkDialog({super.key});

  /// `true` — foydalanuvchi ulashni tanladi.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const TelegramLinkDialog(),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

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
          Icons.send_rounded,
          color: AppColors.primary,
          size: 26,
        ),
      ),
      title: Text(
        s.telegramLinkPromptTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        s.telegramLinkPromptDesc,
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.updateLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.telegramLinkPromptAction),
        ),
      ],
    );
  }
}
