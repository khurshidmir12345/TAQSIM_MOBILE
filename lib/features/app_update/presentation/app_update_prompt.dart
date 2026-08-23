import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_update_provider.dart';
import 'app_update_dialog.dart';

/// Yangilanish modalkasini asosiy sahifada ko'rsatadi.
///
/// Modalka aynan shu yerdan — foydalanuvchi asosiy sahifaga yetib kelgach —
/// chiqariladi. Ilova ochilishida (splash paytida) chiqarilsa, go_router
/// keyingi yo'naltirishda butun route stack'ini almashtiradi va modalka
/// hech kim bosmasdan yopilib ketadi.
///
/// Bir seansda faqat bir marta chiqadi.
Future<void> showAppUpdatePromptIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(appUpdatePromptShownProvider)) return;

  final info = await ref.read(appUpdateCheckProvider.future);
  if (!info.updateAvailable) return;

  // Tekshiruv davomida asosiy sahifa qayta qurilib, funksiya ikkinchi marta
  // chaqirilgan bo'lishi mumkin — modalka ikkitalanib qolmasin.
  if (ref.read(appUpdatePromptShownProvider)) return;
  ref.read(appUpdatePromptShownProvider.notifier).markShown();

  if (!context.mounted) return;

  await AppUpdateDialog.show(context, info);
}
