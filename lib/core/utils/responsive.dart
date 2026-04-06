import 'package:flutter/material.dart';

enum DeviceType { phone, tablet }

class Responsive {
  static DeviceType deviceType(BuildContext context) {
    final w = MediaQuery.sizeOf(context).shortestSide;
    return w >= 600 ? DeviceType.tablet : DeviceType.phone;
  }

  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;

  static double horizontalPadding(BuildContext context) =>
      isTablet(context) ? 32.0 : 20.0;

  static double maxContentWidth(BuildContext context) =>
      isTablet(context) ? 680.0 : double.infinity;
}
