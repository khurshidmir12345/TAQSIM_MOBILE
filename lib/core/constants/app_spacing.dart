import 'package:flutter/material.dart';

/// 8px grid system
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const double borderRadius = 12;
  static const double borderRadiusSm = 8;
  static const double borderRadiusLg = 16;
  static const double borderRadiusXl = 24;
}
