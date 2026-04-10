import 'package:flutter/material.dart';

import '../constants/app_raster_assets.dart';

/// Brend logosi vidjeti — ilova ichida bir xil ko'rinishda ishlatiladi.
/// Logoni o'zgartirish uchun faqat [AppRasterAssets.brandLogo] ni almashtiring.
class TaqsimLogoAsset extends StatelessWidget {
  const TaqsimLogoAsset({
    super.key,
    this.clipRadius = 20,
    this.size,
  });

  final double clipRadius;
  final double? size;

  static const _iconBg = Color(0xFF0E3D32);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(clipRadius),
      child: ColoredBox(
        color: _iconBg,
        child: Transform.scale(
          scale: 1.15,
          child: Image.asset(
            AppRasterAssets.brandLogo,
            fit: BoxFit.cover,
            width: size ?? double.infinity,
            height: size ?? double.infinity,
            gaplessPlayback: true,
            cacheWidth: 512,
          ),
        ),
      ),
    );
  }
}
