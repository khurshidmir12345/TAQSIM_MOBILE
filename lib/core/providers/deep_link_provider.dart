import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/providers/auth_provider.dart';

/// Tashqaridan kelgan deep link'larni (scheme: `taqseem://`) qabul qilib,
/// tegishli harakatlarga yo'naltiradi.
///
/// Eng muhim case — Telegram login tugallangandan so'ng, bot orqali
/// `taqseem://auth/callback?session=XXX` keladi. Bu tokenni olib,
/// zudlik bilan session'ni tekshiramiz va foydalanuvchini tizimga kirgizamiz.
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  final handler = DeepLinkHandler(ref);
  ref.onDispose(handler.dispose);
  return handler;
});

class DeepLinkHandler {
  DeepLinkHandler(this._ref);

  final Ref _ref;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (e) {
      debugPrint('[deep-link] getInitialLink failed: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('[deep-link] stream error: $e'),
    );
  }

  Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'taqseem') return;

    final path = '${uri.host}${uri.path}'.replaceAll(RegExp(r'/+$'), '');

    if (path == 'auth/callback' || path == 'auth') {
      final token = uri.queryParameters['session'];
      if (token == null || token.isEmpty) return;
      await _completeTelegramLogin(token);
    }
  }

  Future<void> _completeTelegramLogin(String sessionToken) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      final result = await repo.checkTelegramSession(sessionToken);

      if (result.status == 'completed' && result.user != null) {
        _ref
            .read(authProvider.notifier)
            .setAuthenticatedFromTelegram(result.user!);
        await _ref.read(shopProvider.notifier).loadShops();
      }
    } catch (e) {
      debugPrint('[deep-link] telegram login failed: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
