import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/providers/auth_provider.dart';

class TelegramAuthScreen extends ConsumerStatefulWidget {
  const TelegramAuthScreen({super.key});

  @override
  ConsumerState<TelegramAuthScreen> createState() => _TelegramAuthScreenState();
}

class _TelegramAuthScreenState extends ConsumerState<TelegramAuthScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _sessionToken;
  bool _isCreatingSession = true;
  String? _error;
  Timer? _pollTimer;
  int _pollCount = 0;
  bool _isPolling = false;

  late final AnimationController _pulseCtl;
  late final Animation<double> _pulseAnim;

  static const _pollInterval = Duration(seconds: 3);
  static const _maxPolls = 200;
  static const _telegramBlue = Color(0xFF229ED9);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtl, curve: Curves.easeInOut),
    );
    _startFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _pulseCtl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Foydalanuvchi Telegram'dan qaytib ilovaga kirganda 3 soniya kutmasdan
    // darhol session statusini tekshiramiz.
    if (state == AppLifecycleState.resumed &&
        _sessionToken != null &&
        !_isCreatingSession &&
        _error == null) {
      _poll();
    }
  }

  Future<void> _startFlow() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.createTelegramSession();

      _sessionToken = result.sessionToken;

      final url = Uri.parse(
        'https://t.me/${result.botUsername}?start=${result.sessionToken}',
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);

      if (mounted) {
        setState(() => _isCreatingSession = false);
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
          _error = e.toString();
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_sessionToken == null || !mounted || _isPolling) return;
    _isPolling = true;
    _pollCount++;

    if (_pollCount > _maxPolls) {
      _pollTimer?.cancel();
      _isPolling = false;
      if (mounted) {
        setState(() => _error = S.of(context).telegramSessionExpired);
      }
      return;
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.checkTelegramSession(_sessionToken!);

      if (result.status == 'completed' && result.user != null) {
        _pollTimer?.cancel();
        if (!mounted) return;

        ref.read(authProvider.notifier).setAuthenticatedFromTelegram(
              result.user!,
            );
        await ref.read(shopProvider.notifier).loadShops();
        if (!mounted) return;

        final shops = ref.read(shopProvider).shops;
        context.go(shops.isEmpty ? '/shop-select' : '/shell');
        return;
      }
    } catch (_) {
      // Tarmoq xatoligi — keyingi pollingda yana urinib ko'ramiz.
    } finally {
      _isPolling = false;
    }
  }

  void _retry() {
    _pollTimer?.cancel();
    _pollCount = 0;
    setState(() {
      _isCreatingSession = true;
      _error = null;
      _sessionToken = null;
    });
    _startFlow();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/login'),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              _buildContent(s, cs, theme),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(S s, ColorScheme cs, ThemeData theme) {
    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onRetry: _retry,
        onBack: () => context.go('/login'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _telegramBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.telegram_rounded,
              size: 56,
              color: _telegramBlue,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isCreatingSession
              ? s.telegramConnecting
              : s.telegramWaitingTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _isCreatingSession
              ? s.telegramConnectingHint
              : s.telegramWaitingHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (!_isCreatingSession) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _telegramBlue.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              if (_sessionToken != null) {
                launchUrl(
                  Uri.parse(
                    'https://t.me/t_register_bot?start=$_sessionToken',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(s.telegramOpenAgain),
            style: TextButton.styleFrom(
              foregroundColor: _telegramBlue,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            s.cancelShort,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          s.snackbarErrorGeneric,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
            ),
            child: Text(
              s.telegramRetry,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBack,
          child: Text(
            s.telegramBackToLogin,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
