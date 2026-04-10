import 'package:flutter/material.dart';

import '../../../../core/constants/app_raster_assets.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';

/// `assets/svg/app_images` dagi barcha rasmlarni bir sahifada ko‘rsatadi (dizayn tekshiruvi).
class AssetImagesPreviewScreen extends StatelessWidget {
  const AssetImagesPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tr('assetImagesPreview')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: AppRasterAssets.previewPaths.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, i) {
          final path = AppRasterAssets.previewPaths[i];
          final fileName = path.split('/').last;
          return Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColoredBox(
                        color: cs.surface,
                        child: Image.asset(
                          path,
                          fit: BoxFit.contain,
                          errorBuilder: (context, err, st) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Yuklanmadi: $err',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
