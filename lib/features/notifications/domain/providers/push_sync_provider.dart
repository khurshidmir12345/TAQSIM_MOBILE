import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/push/push_service.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import 'notification_provider.dart';

/// Foydalanuvchi tizimga kirganda FCM tokenini serverga bog'laydi.
///
/// Token faqat autentifikatsiyadan keyin yuboriladi — endpoint himoyalangan
/// va token aynan shu qurilma sessiyasiga yoziladi.
final pushSyncProvider = Provider<PushSync>((ref) {
  final sync = PushSync(ref);
  ref.onDispose(sync.dispose);

  return sync;
});

class PushSync {
  PushSync(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _refreshSub;
  bool _started = false;
  String? _lastSent;

  /// Ilova ishga tushganda bir marta chaqiriladi.
  void start() {
    if (_started) return;
    _started = true;

    // Kirish/chiqishni kuzatamiz.
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        unawaited(_register());
      } else if (previous?.status == AuthStatus.authenticated) {
        _lastSent = null;
      }
    }, fireImmediately: true);

    // Firebase tokenni vaqti-vaqti bilan almashtiradi.
    _refreshSub = PushService.tokenRefresh.listen((token) {
      _lastSent = null;
      unawaited(_register(known: token));
    });
  }

  Future<void> _register({String? known}) async {
    if (_ref.read(authProvider).status != AuthStatus.authenticated) return;

    final granted = await PushService.requestPermission();

    if (!granted) {
      debugPrint('[push] foydalanuvchi ruxsat bermadi');

      return;
    }

    final token = known ?? await PushService.token();

    if (token == null || token.isEmpty || token == _lastSent) return;

    try {
      await _ref
          .read(notificationRepositoryProvider)
          .registerPushToken(token, PushService.platform);
      _lastSent = token;
      debugPrint('[push] token ro\'yxatdan o\'tdi');
    } catch (e) {
      // Tarmoq xatosi — keyingi kirishda qayta uriniladi.
      debugPrint('[push] token yuborilmadi: $e');
    }
  }

  void dispose() {
    _refreshSub?.cancel();
  }
}
