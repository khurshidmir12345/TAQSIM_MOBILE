import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_update/domain/app_update_provider.dart';
import '../../app_update/domain/models/app_update_info.dart';
import '../../auth/domain/providers/auth_provider.dart';

/// Asosiy sahifa ochilganda ko'rsatiladigan taklif.
///
/// Bir vaqtda faqat bittasi chiqadi va tartib qat'iy: yangilanish bo'lsa
/// faqat o'sha ko'rsatiladi. Eski versiyada turgan odamni avval yangilashga
/// undash kerak — Telegram ulash undan keyingi tashvish.
enum StartupPrompt {
  /// Hech narsa ko'rsatilmaydi.
  none,

  /// Do'konda yangiroq versiya bor.
  appUpdate,

  /// Telegram ulanmagan — biz bilan bog'lanish kanali yo'q.
  telegramLink,
}

class StartupPromptState {
  const StartupPromptState({this.prompt = StartupPrompt.none, this.update});

  final StartupPrompt prompt;

  /// `appUpdate` uchun serverdan kelgan ma'lumot.
  final AppUpdateInfo? update;

  bool get isVisible => prompt != StartupPrompt.none;
}

/// Qaysi taklif ko'rsatilishini hal qiladi va uni yopilgunicha ushlab turadi.
///
/// Taklif ataylab Navigator route (`showDialog`) sifatida chiqarilmaydi:
/// splash `context.go('/shell')` qilganda o'tish animatsiyasi davomida
/// ikkala sahifa ham daraxtda bo'ladi va shu paytda qo'yilgan dialog splash
/// sahifasiga bog'lanib qoladi — splash olib tashlanishi bilan dialog ham
/// yo'qolardi. Shell ichida oddiy widget sifatida chizilganda bunday
/// bog'liqlik umuman bo'lmaydi.
class StartupPromptNotifier extends Notifier<StartupPromptState> {
  /// Bir seansda bir marta hal qilinadi.
  bool _resolved = false;

  @override
  StartupPromptState build() => const StartupPromptState();

  /// Asosiy sahifa chizilgach chaqiriladi.
  Future<void> resolve() async {
    if (_resolved) return;
    _resolved = true;

    // 1. Yangilanish — eng ustuvori.
    final info = await ref.read(appUpdateCheckProvider.future);
    if (info.updateAvailable) {
      state = StartupPromptState(prompt: StartupPrompt.appUpdate, update: info);
      return;
    }

    // 2. Yangilanish bo'lmasa — Telegram ulanmaganini so'raymiz.
    //    Faqat egaga: xodim biznes hisobini boshqarmaydi.
    if (!ref.read(isOwnerProvider)) return;

    final user = ref.read(authProvider).user;
    if (user == null || user.telegramChatId != null) return;

    state = const StartupPromptState(prompt: StartupPrompt.telegramLink);
  }

  /// Foydalanuvchi tugmalardan birini bosdi.
  void dismiss() => state = const StartupPromptState();
}

final startupPromptProvider =
    NotifierProvider<StartupPromptNotifier, StartupPromptState>(
      StartupPromptNotifier.new,
    );
