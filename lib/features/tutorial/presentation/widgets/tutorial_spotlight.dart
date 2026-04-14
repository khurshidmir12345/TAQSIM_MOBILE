import 'package:flutter/material.dart';

/// Bitta element ustida spotlight ko'rsatuvchi overlay.
///
/// Foydalanish:
///   SpotlightOverlay(
///     targetKey: _myBtnKey,
///     title: "Sozlamalar",
///     message: "Bu yerdan sozlang",
///     accentColor: AppColors.primary,
///     onDismiss: () => ...,
///     child: Scaffold(...),
///   )
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({
    super.key,
    required this.child,
    required this.targetKey,
    required this.title,
    required this.message,
    required this.accentColor,
    required this.onDismiss,
    this.spotlightPadding = const EdgeInsets.all(10),
    this.spotlightRadius = 16.0,
  });

  final Widget child;
  final GlobalKey targetKey;
  final String title;
  final String message;
  final Color accentColor;
  final VoidCallback onDismiss;
  final EdgeInsets spotlightPadding;
  final double spotlightRadius;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay>
    with TickerProviderStateMixin {
  Rect? _targetRect;
  final _stackKey = GlobalKey();

  late final AnimationController _pulseCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final AnimationController _fadeCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
    });
  }

  void _updateRect() {
    if (!mounted) return;

    final targetCtx = widget.targetKey.currentContext;
    if (targetCtx == null) return;
    final targetBox = targetCtx.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) return;

    final stackCtx = _stackKey.currentContext;
    if (stackCtx == null) return;
    final stackBox = stackCtx.findRenderObject() as RenderBox?;
    if (stackBox == null) return;

    final pos = targetBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final size = targetBox.size;
    final p = widget.spotlightPadding;

    final rect = Rect.fromLTWH(
      pos.dx - p.left,
      pos.dy - p.top,
      size.width + p.horizontal,
      size.height + p.vertical,
    );
    if (rect == _targetRect) return;
    setState(() => _targetRect = rect);
    _fadeCtl.forward(from: 0);
  }

  @override
  void dispose() {
    _pulseCtl.dispose();
    _fadeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        widget.child,
        if (_targetRect != null)
          FadeTransition(
            opacity: _fadeAnim,
            child: _Overlay(
              targetRect: _targetRect!,
              radius: widget.spotlightRadius,
              accentColor: widget.accentColor,
              pulseAnimation: _pulseCtl,
              title: widget.title,
              message: widget.message,
              onDismiss: widget.onDismiss,
            ),
          ),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.targetRect,
    required this.radius,
    required this.accentColor,
    required this.pulseAnimation,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  final Rect targetRect;
  final double radius;
  final Color accentColor;
  final Animation<double> pulseAnimation;
  final String title;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackH = constraints.maxHeight;
        final stackW = constraints.maxWidth;
        final showAbove = targetRect.center.dy > stackH * 0.50;

        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, _) => CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: targetRect,
                    radius: radius,
                    accentColor: accentColor,
                    pulseValue: pulseAnimation.value,
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onDismiss,
                child: const SizedBox.expand(),
              ),
            ),

            Positioned(
              left: (targetRect.center.dx - 14).clamp(8.0, stackW - 36.0),
              top: showAbove ? targetRect.top - 44 : targetRect.bottom + 8,
              child: IgnorePointer(
                child: _AnimatedArrow(
                  pointUp: !showAbove,
                  color: accentColor,
                  animation: pulseAnimation,
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              top: showAbove
                  ? null
                  : (targetRect.bottom + 52).clamp(0.0, stackH - 160),
              bottom: showAbove
                  ? (stackH - targetRect.top + 44).clamp(8.0, stackH - 160)
                  : null,
              child: GestureDetector(
                onTap: onDismiss,
                child: _TooltipCard(
                  title: title,
                  message: message,
                  accentColor: accentColor,
                  onClose: onDismiss,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.targetRect,
    required this.radius,
    required this.accentColor,
    required this.pulseValue,
  });

  final Rect targetRect;
  final double radius;
  final Color accentColor;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    canvas.saveLayer(fullRect, Paint());

    canvas.drawRect(
      fullRect,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );

    final glowR = radius + 6 + 8 * pulseValue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        targetRect.inflate(glowR - radius),
        Radius.circular(glowR),
      ),
      Paint()
        ..color = accentColor.withValues(alpha: 0.18 + 0.14 * pulseValue)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + 6 * pulseValue),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, Radius.circular(radius)),
      Paint()..blendMode = BlendMode.clear,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.pulseValue != pulseValue ||
      old.targetRect != targetRect ||
      old.accentColor != accentColor;
}

class _AnimatedArrow extends StatelessWidget {
  const _AnimatedArrow({
    required this.pointUp,
    required this.color,
    required this.animation,
  });

  final bool pointUp;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, (pointUp ? -5 : 5) * animation.value),
        child: Icon(
          pointUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: color,
          size: 28,
          shadows: [
            Shadow(color: color.withValues(alpha: 0.55), blurRadius: 12),
          ],
        ),
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.title,
    required this.message,
    required this.accentColor,
    required this.onClose,
  });

  final String title;
  final String message;
  final Color accentColor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2235) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.28 : 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
