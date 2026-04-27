import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../router/app_router.dart';

/// Tashqaridan kelgan deep link'larni (scheme: `taqseem://`) qabul qilib,
/// tegishli harakatlarga yo'naltiradi.
///
/// Eng muhim use-case — Telegram login tugallangandan so'ng, bot orqali
/// `taqseem://auth/callback?session=XXX` keladi. Bu tokenni olib, zudlik
/// bilan session'ni tekshiramiz, foydalanuvchini tizimga kirgizamiz va
/// asosiy ekranga o'tkazib yuboramiz.
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

  /// Webhook bilan deep-link o'rtasida tarmoq latency bo'lishi mumkin.
  /// Shuning uchun session `pending` qaytsa, bir necha marta qayta urinamiz.
  static const _maxSessionRetries = 4;
  static const _retryDelay = Duration(milliseconds: 900);

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        debugPrint('[deep-link] initial uri: $initial');
        await _handle(initial);
      }
    } catch (e) {
      debugPrint('[deep-link] getInitialLink failed: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[deep-link] stream uri: $uri');
        _handle(uri);
      },
      onError: (Object e) => debugPrint('[deep-link] stream error: $e'),
    );
  }

  Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'taqseem') {
      debugPrint('[deep-link] unsupported scheme: ${uri.scheme}');
      return;
    }

    final path = '${uri.host}${uri.path}'.replaceAll(RegExp(r'/+$'), '');
    debugPrint('[deep-link] normalized path: "$path"');

    if (path == 'auth/callback' || path == 'auth') {
      final token = uri.queryParameters['session'];
      if (token == null || token.isEmpty) {
        debugPrint('[deep-link] missing session token in $uri');
        return;
      }
      await _completeTelegramLogin(token);
    }
  }

  Future<void> _completeTelegramLogin(String sessionToken) async {
    final repo = _ref.read(authRepositoryProvider);

    for (var attempt = 1; attempt <= _maxSessionRetries; attempt++) {
      try {
        final result = await repo.checkTelegramSession(sessionToken);
        debugPrint(
          '[deep-link] session check #$attempt → status=${result.status}',
        );

        if (result.status == 'completed' && result.user != null) {
          await _finalizeLogin(result.user!);
          return;
        }

        if (result.status == 'pending' && attempt < _maxSessionRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }

        debugPrint('[deep-link] stopping retries: status=${result.status}');
        return;
      } catch (e) {
        debugPrint('[deep-link] attempt #$attempt failed: $e');
        if (attempt < _maxSessionRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }
  }

  Future<void> _finalizeLogin(UserModel user) async {
    _ref.read(authProvider.notifier).setAuthenticatedFromTelegram(user);

    try {
      await _ref.read(shopProvider.notifier).loadShops();
    } catch (e) {
      debugPrint('[deep-link] loadShops failed: $e');
    }

    final shops = _ref.read(shopProvider).shops;
    final target = shops.isEmpty ? '/shop-select' : '/shell';
    debugPrint('[deep-link] navigating to $target (shops=${shops.length})');

    // Explicit navigation — GoRouter `refreshListenable` orqali auto-redirect
    // ham ishlaydi, lekin bu yerda aniq `router.go()` chaqirib, race
    // condition'larga yo'l qo'ymaymiz (cold start, stale screen va h.k.).
    try {
      _ref.read(routerProvider).go(target);
    } catch (e) {
      debugPrint('[deep-link] explicit navigation failed: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
