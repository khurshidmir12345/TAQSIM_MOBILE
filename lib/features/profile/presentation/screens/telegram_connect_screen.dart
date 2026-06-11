import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Mavjud foydalanuvchiga Telegramni bog'lash uchun qadamma-qadam ekran.
///
/// Oqim: intro → (Telegram ochiladi) → waiting (polling) → success / error.
/// Backend `/auth/telegram/connect-session` va `/auth/telegram/connect-status`
/// endpointlaridan foydalanadi.
class TelegramConnectScreen extends ConsumerStatefulWidget {
  const TelegramConnectScreen({super.key});

  @override
  ConsumerState<TelegramConnectScreen> createState() =>
      _TelegramConnectScreenState();
}

enum _Step { intro, waiting, success, error }

class _TelegramConnectScreenState extends ConsumerState<TelegramConnectScreen>
    with WidgetsBindingObserver {
  static const _telegramBlue = Color(0xFF2AABEE);
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPolls = 200;

  _Step _step = _Step.intro;
  String? _sessionToken;
  String? _botUsername;
  bool _isLaunching = false;
  bool _isPolling = false;
  int _pollCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _step == _Step.waiting) {
      _poll();
    }
  }

  Future<void> _startConnect() async {
    HapticFeedback.selectionClick();
    setState(() => _isLaunching = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.createTelegramConnectSession();
      _sessionToken = result.sessionToken;
      _botUsername = result.botUsername;

      await launchUrl(
        Uri.parse('https://t.me/${result.botUsername}?start=${result.sessionToken}'),
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;
      setState(() {
        _isLaunching = false;
        _step = _Step.waiting;
      });
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLaunching = false;
        _step = _Step.error;
      });
    }
  }

  void _reopenTelegram() {
    if (_sessionToken == null || _botUsername == null) return;
    HapticFeedback.selectionClick();
    launchUrl(
      Uri.parse('https://t.me/$_botUsername?start=$_sessionToken'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_sessionToken == null || !mounted || _isPolling) return;
    _isPolling = true;
    _pollCount++;

    if (_pollCount > _maxPolls) {
      _pollTimer?.cancel();
      _isPolling = false;
      if (mounted) setState(() => _step = _Step.error);
      return;
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.checkTelegramConnectStatus(_sessionToken!);

      if (!mounted) return;

      if (result.status == 'completed') {
        _pollTimer?.cancel();
        if (result.user != null) {
          ref.read(authProvider.notifier).setUser(result.user!);
        }
        HapticFeedback.lightImpact();
        setState(() => _step = _Step.success);
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) context.pop(true);
        });
      } else if (result.status == 'failed') {
        _pollTimer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _step = _Step.error);
      }
    } catch (_) {
      // Tarmoq xatosi — keyingi pollingda yana urinamiz.
    } finally {
      _isPolling = false;
    }
  }

  void _retry() {
    _pollTimer?.cancel();
    _pollCount = 0;
    _sessionToken = null;
    _botUsername = null;
    setState(() => _step = _Step.intro);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          s.tgConnectTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            _Step.intro => _IntroView(
                key: const ValueKey('intro'),
                isLaunching: _isLaunching,
                onConnect: _startConnect,
              ),
            _Step.waiting => _WaitingView(
                key: const ValueKey('waiting'),
                onReopen: _reopenTelegram,
                onCancel: () => context.pop(),
              ),
            _Step.success => const _SuccessView(key: ValueKey('success')),
            _Step.error => _ErrorView(
                key: const ValueKey('error'),
                onRetry: _retry,
                onCancel: () => context.pop(),
              ),
          },
        ),
      ),
    );
  }
}

// ─── Telegram brand badge ────────────────────────────────────────────────────

class _TelegramBadge extends StatelessWidget {
  const _TelegramBadge();

  static const double size = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF37BBFE), Color(0xFF007DBB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x332AABEE),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.send_rounded, color: Colors.white, size: size * 0.46),
    );
  }
}

// ─── Intro (steps + CTA) ─────────────────────────────────────────────────────

class _IntroView extends StatelessWidget {
  const _IntroView({super.key, required this.isLaunching, required this.onConnect});

  final bool isLaunching;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _TelegramBadge(),
          const SizedBox(height: 24),
          Text(
            s.tgConnectTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.tgConnectSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          _StepTile(number: 1, text: s.tgConnectStep1),
          _StepTile(number: 2, text: s.tgConnectStep2),
          _StepTile(number: 3, text: s.tgConnectStep3, isLast: true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isLaunching ? null : onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: _TelegramConnectScreenState._telegramBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _TelegramConnectScreenState._telegramBlue.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
              ),
              icon: isLaunching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                s.tgConnectOpen,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.text, this.isLast = false});

  final int number;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _TelegramConnectScreenState._telegramBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: _TelegramConnectScreenState._telegramBlue,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Waiting ─────────────────────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  const _WaitingView({super.key, required this.onReopen, required this.onCancel});

  final VoidCallback onReopen;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _TelegramBadge(),
          const SizedBox(height: 32),
          Text(
            s.tgConnectWaitingTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.tgConnectWaitingHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                _TelegramConnectScreenState._telegramBlue,
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextButton.icon(
            onPressed: onReopen,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(s.telegramOpenAgain),
            style: TextButton.styleFrom(
              foregroundColor: _TelegramConnectScreenState._telegramBlue,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onCancel,
            child: Text(
              s.cancel,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success ─────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 56),
          ),
          const SizedBox(height: 28),
          Text(
            s.tgConnectSuccessTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.tgConnectSuccessHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error ───────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.onRetry, required this.onCancel});

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 52),
          ),
          const SizedBox(height: 28),
          Text(
            s.tgConnectErrorTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.tgConnectErrorHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
              ),
              child: Text(
                s.telegramRetry,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onCancel,
            child: Text(
              s.cancel,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
