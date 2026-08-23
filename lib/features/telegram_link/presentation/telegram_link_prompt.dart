import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/providers/auth_provider.dart';
import '../domain/telegram_link_provider.dart';
import 'telegram_link_dialog.dart';

/// Telegram ulanmagan bo'lsa — asosiy sahifada bir marta taklif qiladi.
///
/// Nega kerak: hisob bilan bog'liq muhim xabarlar va qo'llab-quvvatlash
/// Telegram bot orqali boradi. Telegram ulanmagan foydalanuvchiga biz
/// umuman yeta olmaymiz.
///
/// Faqat egaga ko'rsatiladi: xodim biznes hisobini boshqarmaydi, unga bu
/// taklif ma'nosiz.
Future<void> showTelegramLinkPromptIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(telegramLinkPromptShownProvider)) return;

  if (!ref.read(isOwnerProvider)) return;

  final user = ref.read(authProvider).user;
  if (user == null || user.telegramChatId != null) return;

  ref.read(telegramLinkPromptShownProvider.notifier).markShown();

  if (!context.mounted) return;

  final wantsToLink = await TelegramLinkDialog.show(context);

  if (wantsToLink && context.mounted) {
    context.push('/telegram-connect');
  }
}
