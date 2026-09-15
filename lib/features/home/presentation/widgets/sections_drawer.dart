import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';

/// Bo'limlar qatlami: fon xiralashadi, o'ng chetda ikonkali tugmalar va
/// yonida oq yorliq suzib chiqadi. Bo'sh joyga bosilsa yopiladi.
///
/// Asosiy sahifada o'ng chetdan chapga tortilsa yoki chetdagi dastak
/// bosilsa ochiladi. Yangi bo'lim — [_sections] ro'yxatiga bitta qator.
Future<void> showSectionsOverlay(BuildContext context) {
  HapticFeedback.selectionClick();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: S.of(context).sectionsDrawerTitle,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) => const _SectionsOverlay(),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

class _Section {
  const _Section({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String Function(S s) label;
  final String route;
}

const List<_Section> _sections = [
  _Section(
    icon: Icons.storefront_rounded,
    label: _outletsLabel,
    route: '/outlets',
  ),
];

String _outletsLabel(S s) => s.outletsTitle;

class _SectionsOverlay extends StatelessWidget {
  const _SectionsOverlay();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Xira, biroz qoraygan fon — orqadagi sahifa ko'rinib turadi.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.32),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < _sections.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == _sections.length - 1 ? 0 : 14,
                        ),
                        child: _SectionButton(
                          index: i,
                          icon: _sections[i].icon,
                          label: _sections[i].label(s),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            context.push(_sections[i].route);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bitta bo'lim: chapda oq yorliq, o'ngda gradientli ikonka kvadrati.
/// Har biri o'z navbatida o'ngdan suzib kiradi.
class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 60),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(48 * (1 - t), 0),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yorliq.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: isDark ? Colors.white : const Color(0xFF0D2626),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ikonka.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asosiy sahifaning o'ng cheti: yupqa dastak (bosilsa ochiladi) va butun
/// balandlikdagi ko'rinmas chiziq — chapga tortilsa ochiladi.
class SectionsEdgeHandle extends StatefulWidget {
  const SectionsEdgeHandle({super.key});

  @override
  State<SectionsEdgeHandle> createState() => _SectionsEdgeHandleState();
}

class _SectionsEdgeHandleState extends State<SectionsEdgeHandle> {
  bool _opened = false;

  void _open() {
    if (_opened) return;
    _opened = true;
    showSectionsOverlay(context).whenComplete(() => _opened = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: S.of(context).sectionsDrawerTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _open,
        onHorizontalDragUpdate: (d) {
          if (d.delta.dx < -4) _open();
        },
        child: SizedBox(
          width: 22,
          child: Center(
            child: Container(
              width: 4,
              height: 42,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
