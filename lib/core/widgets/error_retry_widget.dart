import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../l10n/translations.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final s = S.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.error.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: cs.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(s.tryAgain),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm + 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
