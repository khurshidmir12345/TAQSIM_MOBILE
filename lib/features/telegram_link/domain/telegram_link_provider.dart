import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Telegram ulash taklifi shu seansda ko'rsatilganmi.
///
/// Asosiy sahifa qayta qurilishi mumkin (tab almashish, ruxsat yangilanishi,
/// logout/login) — taklif esa ilovaga bir kirishda bir marta chiqadi.
class TelegramLinkPromptShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

final telegramLinkPromptShownProvider =
    NotifierProvider<TelegramLinkPromptShownNotifier, bool>(
  TelegramLinkPromptShownNotifier.new,
);
