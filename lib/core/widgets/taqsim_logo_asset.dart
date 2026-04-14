import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_raster_assets.dart';

/// Brend logosi widget — ilova ichida barcha joylarda bir xil premium ko'rinish.
/// Logoni o'zgartirish uchun faqat [AppRasterAssets.brandLogo] faylini almashtiring.
class TaqsimLogoAsset extends StatelessWidget {
  const TaqsimLogoAsset({
    super.key,
    this.clipRadius = 20,
    this.size,
    this.showGoldRing = false,
  });

  final double clipRadius;
  final double? size;

  /// Splash / onboarding ekranlarida gold gradient ring ko'rsatish uchun
  final bool showGoldRing;

  @override
  Widget build(BuildContext context) {
    final s = size ?? double.infinity;
    final logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(clipRadius),
      child: Image.asset(
        AppRasterAssets.brandLogo,
        fit: BoxFit.cover,
        width: s,
        height: s,
        gaplessPlayback: true,
        cacheWidth: 512,
      ),
    );

    if (!showGoldRing) return logoWidget;

    final ringWidth = (size ?? 100) * 0.04;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(clipRadius + ringWidth + 2),
        gradient: const LinearGradient(
          colors: AppColors.goldGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.45),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.all(ringWidth),
      child: logoWidget,
    );
  }
}

/// Splash ekrani uchun maxsus logo — pulsing glow animatsiyasi bilan.
class TaqsimSplashLogo extends StatefulWidget {
  const TaqsimSplashLogo({
    super.key,
    required this.size,
    required this.scaleAnim,
  });

  final double size;
  final Animation<double> scaleAnim;

  @override
  State<TaqsimSplashLogo> createState() => _TaqsimSplashLogoState();
}

class _TaqsimSplashLogoState extends State<TaqsimSplashLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final radius = s * 0.28;

    return ScaleTransition(
      scale: widget.scaleAnim,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          final glowOpacity = 0.12 + _pulseAnim.value * 0.20;
          final glowSpread = 4.0 + _pulseAnim.value * 10.0;
          final glowBlur = 20.0 + _pulseAnim.value * 24.0;

          return Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                // Chuqur soya
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
                // Gold glow — pulsing
                BoxShadow(
                  color: AppColors.goldLight.withValues(alpha: glowOpacity),
                  blurRadius: glowBlur,
                  spreadRadius: glowSpread,
                ),
                // Teal glow
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.20),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: _GoldRingLogo(size: s, radius: radius),
      ),
    );
  }
}

/// Gold gradient ring ichida logo — premium brend ko'rinishi.
class _GoldRingLogo extends StatelessWidget {
  const _GoldRingLogo({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    const ringWidth = 2.5;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8CC6A), Color(0xFFC8A227), Color(0xFFE8CC6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.all(ringWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - ringWidth),
        child: Image.asset(
          AppRasterAssets.brandLogo,
          fit: BoxFit.cover,
          width: size - ringWidth * 2,
          height: size - ringWidth * 2,
          gaplessPlayback: true,
          cacheWidth: 512,
        ),
      ),
    );
  }
}
