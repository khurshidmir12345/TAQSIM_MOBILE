import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/core/api/api_provider.dart';
import 'package:taqseem/features/app_update/domain/app_update_provider.dart';
import 'package:taqseem/features/app_update/domain/models/app_update_info.dart';
import 'package:taqseem/features/auth/domain/models/user_model.dart';
import 'package:taqseem/features/auth/domain/providers/auth_provider.dart';
import 'package:taqseem/features/shell/domain/startup_prompt_provider.dart';

/// Taklif tanlash qoidasi.
///
/// Bir vaqtda faqat bittasi chiqadi. Yangilanish bor ekan, Telegram taklifi
/// umuman ko'rsatilmaydi: eski versiyada turgan odamni avval yangilashga
/// undash kerak.
void main() {
  const withUpdate = AppUpdateInfo(
    enabled: true,
    updateAvailable: true,
    latestVersion: '1.2.8',
    storeUrl: 'https://play.google.com/store/apps/details?id=uz.taqseem.mobile',
  );
  const noUpdate = AppUpdateInfo.none();

  UserModel user({int? telegramChatId, String userType = 'owner'}) {
    return UserModel(
      id: 'u1',
      name: 'Test',
      phone: '+998900000000',
      userType: userType,
      telegramChatId: telegramChatId,
    );
  }

  ProviderContainer make({
    required AppUpdateInfo update,
    required UserModel currentUser,
  }) {
    final container = ProviderContainer(
      overrides: [
        appUpdateCheckProvider.overrideWith((ref) async => update),
        authProvider.overrideWith(() => _StubAuth(currentUser)),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  Future<StartupPromptState> resolve(ProviderContainer c) async {
    await c.read(startupPromptProvider.notifier).resolve();

    return c.read(startupPromptProvider);
  }

  test('yangilanish bor — faqat yangilanish taklifi', () async {
    final c = make(update: withUpdate, currentUser: user());

    final state = await resolve(c);

    expect(state.prompt, StartupPrompt.appUpdate);
    expect(state.update?.updateAvailable, isTrue);
  });

  test('yangilanish bor, Telegram ham ulanmagan — baribir faqat yangilanish',
      () async {
    final c = make(update: withUpdate, currentUser: user());

    final state = await resolve(c);

    expect(state.prompt, StartupPrompt.appUpdate);
    expect(state.prompt, isNot(StartupPrompt.telegramLink));
  });

  test('yangilanish yo\'q, Telegram ulanmagan — Telegram taklifi', () async {
    final c = make(update: noUpdate, currentUser: user());

    expect((await resolve(c)).prompt, StartupPrompt.telegramLink);
  });

  test('yangilanish yo\'q, Telegram ulangan — hech narsa', () async {
    final c = make(update: noUpdate, currentUser: user(telegramChatId: 555));

    expect((await resolve(c)).prompt, StartupPrompt.none);
  });

  /// Xodim biznes hisobini boshqarmaydi — unga bu taklif ma'nosiz.
  test('xodimga Telegram taklifi ko\'rsatilmaydi', () async {
    final c = make(update: noUpdate, currentUser: user(userType: 'seller'));

    expect((await resolve(c)).prompt, StartupPrompt.none);
  });

  test('bir seansda bir marta hal qilinadi', () async {
    final c = make(update: noUpdate, currentUser: user());

    expect((await resolve(c)).prompt, StartupPrompt.telegramLink);

    c.read(startupPromptProvider.notifier).dismiss();
    expect(c.read(startupPromptProvider).isVisible, isFalse);

    // Asosiy sahifa qayta qurilsa ham taklif qaytib chiqmaydi.
    expect((await resolve(c)).prompt, StartupPrompt.none);
  });
}

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);

  final UserModel _user;

  @override
  AuthState build() {
    // Haqiqiy notifier qurilishida tokenni o'qiydi — testda kerak emas.
    ref.read(apiClientProvider);

    return AuthState(status: AuthStatus.authenticated, user: _user);
  }
}
