import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Brand Primary — Teal ─────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1A7878);
  static const Color primaryLight = Color(0xFF2A9E9E);
  static const Color primaryDark  = Color(0xFF145E5E);

  // ─── Brand Accent — Gold ──────────────────────────────────────────────────
  static const Color gold        = Color(0xFFC8A227);
  static const Color goldLight   = Color(0xFFE8CC6A);
  static const Color goldBorder  = Color(0xFFD4B440);
  static const Color goldMuted   = Color(0xFFF5EDD0);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  /// Income / profit — green
  static const Color income  = Color(0xFF2E7D32);
  static const Color success = Color(0xFF2E7D32);

  static const Color error   = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info    = Color(0xFF1565C0);

  // ─── Light Mode ───────────────────────────────────────────────────────────
  static const Color background      = Color(0xFFF2F7F7);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFE8F0F0);

  static const Color textPrimary   = Color(0xFF0D2626);
  static const Color textSecondary = Color(0xFF4A6464);
  static const Color textHint      = Color(0xFF9AB0B0);

  static const Color border  = Color(0xFFD4E4E4);
  static const Color divider = Color(0xFFE4EDED);

  // ─── Dark Mode ────────────────────────────────────────────────────────────
  static const Color darkBackground     = Color(0xFF0F1A1A);
  static const Color darkSurface        = Color(0xFF1A2828);
  static const Color darkSurfaceVariant = Color(0xFF243434);

  static const Color darkTextPrimary   = Color(0xFFF0F5F5);
  static const Color darkTextSecondary = Color(0xFFAABBBB);
  static const Color darkTextHint      = Color(0xFF6A8080);

  static const Color darkBorder  = Color(0xFF2E4444);
  static const Color darkDivider = Color(0xFF243434);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const List<Color> cardGradient = [
    Color(0xFF1A7878),
    Color(0xFF2A9E9E),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFC8A227),
    Color(0xFFE8CC6A),
  ];

  static const List<Color> splashGradient = [
    Color(0xFF0E5252),
    Color(0xFF1A7878),
    Color(0xFF155F5F),
  ];

  static const List<Color> cardGradientDark = [
    Color(0xFF0D2828),
    Color(0xFF163636),
  ];

  /// Brightness'ga qarab to'g'ri gradient qaytaradi
  static List<Color> headerGradient(Brightness brightness) =>
      brightness == Brightness.dark ? cardGradientDark : cardGradient;

  static List<Color> balanceGradient(Brightness brightness, bool isLoss) {
    if (isLoss) {
      return brightness == Brightness.dark
          ? [const Color(0xFF5C1010), const Color(0xFF7B1A1A)]
          : [const Color(0xFFB71C1C), const Color(0xFFC62828)];
    }
    return headerGradient(brightness);
  }
}
