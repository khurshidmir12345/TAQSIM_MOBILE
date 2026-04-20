import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spotlight overlay that highlights a single widget by its [GlobalKey].
///
/// The overlay is mounted on the **root** [Overlay] so that it covers the
/// entire screen — including any bottom navigation bar owned by an enclosing
/// shell. Visually it dims the whole viewport and cuts a transparent hole
/// around the target. A tooltip card with a gentle, breathing border is
/// displayed next to the hole; the user can dismiss it by tapping the scrim
/// or pressing the primary call-to-action button.
///
/// Usage:
/// ```dart
/// SpotlightOverlay(
///   targetKey: _filterBtnKey,
///   title: 'Dastlab sozlang',
///   message: 'Bu yerdan mahsulotlarni kiriting.',
///   ctaLabel: 'Tushunarli',
///   accentColor: AppColors.primary,
///   onDismiss: () => ...,
///   child: Scaffold(...),
/// )
/// ```
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({
    super.key,
    required this.child,
    required this.targetKey,
    required this.title,
    required this.message,
    required this.accentColor,
    required this.onDismiss,
    required this.ctaLabel,
    this.spotlightPadding = const EdgeInsets.all(10),
    this.spotlightRadius = 16.0,
  });

  final Widget child;
  final GlobalKey targetKey;
  final String title;
  final String message;
  final String ctaLabel;
  final Color accentColor;
  final VoidCallback onDismiss;
  final EdgeInsets spotlightPadding;
  final double spotlightRadius;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay>
    with WidgetsBindingObserver {
  OverlayEntry? _entry;
  Rect? _targetRect;
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _mountOverlay());
  }

  @override
  void didChangeMetrics() {
    _scheduleRemeasure();
  }

  @override
  void didUpdateWidget(covariant SpotlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.message != widget.message ||
        oldWidget.ctaLabel != widget.ctaLabel ||
        oldWidget.accentColor != widget.accentColor) {
      _entry?.markNeedsBuild();
    }
    if (oldWidget.targetKey != widget.targetKey) {
      _scheduleRemeasure();
    }
  }

  void _scheduleRemeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _mountOverlay() {
    if (!mounted) return;
    _measure();
    _entry = OverlayEntry(builder: _buildOverlay);
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_entry!);
  }

  void _measure() {
    if (!mounted) return;
    final targetCtx = widget.targetKey.currentContext;
    if (targetCtx == null) return;
    final box = targetCtx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero);
    final p = widget.spotlightPadding;
    final rect = Rect.fromLTWH(
      topLeft.dx - p.left,
      topLeft.dy - p.top,
      box.size.width + p.horizontal,
      box.size.height + p.vertical,
    );
    final screen = MediaQuery.of(context).size;

    if (rect == _targetRect && screen == _screenSize) return;
    _targetRect = rect;
    _screenSize = screen;
    _entry?.markNeedsBuild();
  }

  Widget _buildOverlay(BuildContext ctx) {
    final rect = _targetRect;
    if (rect == null) return const SizedBox.shrink();
    return _SpotlightLayer(
      targetRect: rect,
      radius: widget.spotlightRadius,
      accentColor: widget.accentColor,
      title: widget.title,
      message: widget.message,
      ctaLabel: widget.ctaLabel,
      onDismiss: _handleDismiss,
    );
  }

  void _handleDismiss() {
    HapticFeedback.selectionClick();
    widget.onDismiss();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Spotlight visual layer ───────────────────────────────────────────────────

class _SpotlightLayer extends StatefulWidget {
  const _SpotlightLayer({
    required this.targetRect,
    required this.radius,
    required this.accentColor,
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.onDismiss,
  });

  final Rect targetRect;
  final double radius;
  final Color accentColor;
  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback onDismiss;

  @override
  State<_SpotlightLayer> createState() => _SpotlightLayerState();
}

class _SpotlightLayerState extends State<_SpotlightLayer>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _enterCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _enterCtl, curve: Curves.easeOut);

  late final Animation<double> _scale = Tween<double>(begin: 0.94, end: 1.0)
      .animate(CurvedAnimation(parent: _enterCtl, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _pulseCtl.dispose();
    _enterCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final showAbove = widget.targetRect.center.dy > screenH * 0.5;

        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseCtl, _fade]),
                builder: (context, _) => CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: widget.targetRect,
                    radius: widget.radius,
                    accentColor: widget.accentColor,
                    pulseValue: _pulseCtl.value,
                    fade: _fade.value,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.onDismiss,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: (widget.targetRect.center.dx - 14)
                  .clamp(8.0, screenW - 36.0),
              top: showAbove
                  ? widget.targetRect.top - 48
                  : widget.targetRect.bottom + 8,
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _fade,
                  child: _AnimatedArrow(
                    pointUp: !showAbove,
                    color: widget.accentColor,
                    animation: _pulseCtl,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: showAbove
                  ? null
                  : (widget.targetRect.bottom + 56)
                      .clamp(0.0, screenH - 200),
              bottom: showAbove
                  ? (screenH - widget.targetRect.top + 48)
                      .clamp(8.0, screenH - 200)
                  : null,
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: showAbove
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  child: _TooltipCard(
                    title: widget.title,
                    message: widget.message,
                    ctaLabel: widget.ctaLabel,
                    accentColor: widget.accentColor,
                    pulse: _pulseCtl,
                    onDismiss: widget.onDismiss,
                  ),
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
    required this.fade,
  });

  final Rect targetRect;
  final double radius;
  final Color accentColor;
  final double pulseValue;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    canvas.saveLayer(fullRect, Paint());

    canvas.drawRect(
      fullRect,
      Paint()..color = Colors.black.withValues(alpha: 0.72 * fade),
    );

    final glowR = radius + 6 + 8 * pulseValue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        targetRect.inflate(glowR - radius),
        Radius.circular(glowR),
      ),
      Paint()
        ..color = accentColor
            .withValues(alpha: (0.18 + 0.14 * pulseValue) * fade)
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
      old.fade != fade ||
      old.targetRect != targetRect ||
      old.accentColor != accentColor;
}

// ─── Arrow ───────────────────────────────────────────────────────────────────

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
        offset: Offset(0, (pointUp ? -6 : 6) * animation.value),
        child: Icon(
          pointUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: color,
          size: 28,
          shadows: [
            Shadow(color: color.withValues(alpha: 0.55), blurRadius: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Tooltip card ────────────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.accentColor,
    required this.pulse,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final String ctaLabel;
  final Color accentColor;
  final Animation<double> pulse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1A2235) : Colors.white;

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final borderAlpha = 0.22 + 0.22 * pulse.value;
        final glowAlpha = 0.18 + 0.12 * pulse.value;

        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withValues(alpha: borderAlpha),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: glowAlpha),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlowIcon(color: accentColor, pulse: pulse),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              fontSize: 15.5,
                              height: 1.25,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _CloseButton(onTap: onDismiss),
                  ],
                ),
                const SizedBox(height: 14),
                _CtaButton(
                  label: ctaLabel,
                  color: accentColor,
                  onTap: onDismiss,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({required this.color, required this.pulse});
  final Color color;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12 + 0.14 * pulse.value),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.tips_and_updates_rounded,
            color: color,
            size: 22,
          ),
        );
      },
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 15,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
