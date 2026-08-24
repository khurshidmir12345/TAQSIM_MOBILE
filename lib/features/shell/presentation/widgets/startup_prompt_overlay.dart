import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_update/presentation/app_update_dialog.dart';
import '../../../telegram_link/presentation/telegram_link_dialog.dart';
import '../../domain/startup_prompt_provider.dart';

/// Asosiy sahifa ustida chiziladigan taklif oynasi.
///
/// `showDialog` ataylab ishlatilmaydi: splash `/shell` ga o'tayotganda
/// o'tish animatsiyasi davomida ikkala sahifa ham daraxtda bo'ladi va shu
/// paytda qo'yilgan dialog splash sahifasiga bog'lanib qolardi — splash
/// olib tashlanishi bilan oyna ham bir zumda yo'q bo'lardi.
///
/// Oddiy widget sifatida chizilganda bunday bog'liqlik yo'q: oyna faqat
/// asosiy sahifa ekranda turganda ko'rinadi va faqat tugma bosilganda
/// yopiladi.
class StartupPromptOverlay extends ConsumerWidget {
  const StartupPromptOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(startupPromptProvider);

    if (!state.isVisible) return const SizedBox.shrink();

    final notifier = ref.read(startupPromptProvider.notifier);

    final card = switch (state.prompt) {
      StartupPrompt.appUpdate => AppUpdateDialog(
        info: state.update!,
        onDismiss: notifier.dismiss,
      ),
      StartupPrompt.telegramLink => TelegramLinkDialog(
        onLater: notifier.dismiss,
        onConnect: () {
          notifier.dismiss();
          context.push('/telegram-connect');
        },
      ),
      StartupPrompt.none => const SizedBox.shrink(),
    };

    return _PromptScrim(child: card);
  }
}

/// Fon qorayishi va oynaning paydo bo'lish animatsiyasi.
///
/// Fon bosilganda hech narsa bo'lmaydi — oyna o'z-o'zidan yopilmaydi.
class _PromptScrim extends StatefulWidget {
  const _PromptScrim({required this.child});

  final Widget child;

  @override
  State<_PromptScrim> createState() => _PromptScrimState();
}

class _PromptScrimState extends State<_PromptScrim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Stack(
        children: [
          // Ortidagi sahifa bilan ishlashning oldini oladi.
          const ModalBarrier(dismissible: false, color: Colors.black54),
          Center(
            child: ScaleTransition(scale: _scale, child: widget.child),
          ),
        ],
      ),
    );
  }
}
