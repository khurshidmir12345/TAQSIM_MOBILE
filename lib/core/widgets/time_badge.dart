import 'package:flutter/material.dart';

/// Ixcham soat chipi — `HH:mm` ko'rinishidagi vaqtni kichik neytral
/// belgi sifatida ko'rsatadi. Card sarlavhalari ichida va ro'yxat
/// elementlarida ishlatish uchun mo'ljallangan.
class TimeBadge extends StatelessWidget {
  const TimeBadge({
    super.key,
    required this.time,
    this.compact = false,
  });

  /// Ko'rsatiladigan vaqt matni (odatda `HH:mm`).
  final String time;

  /// Juda qisqa joylar uchun kompakt rejim (kichikroq padding/font).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = cs.onSurface.withValues(alpha: isDark ? 0.08 : 0.05);
    final fg = cs.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: compact ? 10 : 11,
            color: fg,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            time,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.1,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
