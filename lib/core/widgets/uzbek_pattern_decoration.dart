import 'dart:math' as math;
import 'package:flutter/material.dart';

class UzbekPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  UzbekPatternPainter({
    this.color = Colors.white,
    this.opacity = 0.08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.fill;

    const spacing = 48.0;

    for (double x = -spacing / 2; x < size.width + spacing; x += spacing) {
      for (double y = -spacing / 2; y < size.height + spacing; y += spacing) {
        _drawIslimiMotif(canvas, Offset(x, y), spacing * 0.35, paint, fillPaint);
      }
    }

    final borderPaint = Paint()
      ..color = color.withValues(alpha: opacity * 1.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawBorderPattern(canvas, size, borderPaint);
  }

  void _drawIslimiMotif(
      Canvas canvas, Offset center, double radius, Paint stroke, Paint fill) {
    final path = Path();
    const points = 8;
    final innerR = radius * 0.4;
    final outerR = radius;

    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi / points) - math.pi / 2;
      final nextAngle = ((i + 1) * 2 * math.pi / points) - math.pi / 2;
      final midAngle = angle + (math.pi / points);

      final outerX = center.dx + outerR * math.cos(angle);
      final outerY = center.dy + outerR * math.sin(angle);
      final innerX = center.dx + innerR * math.cos(midAngle);
      final innerY = center.dy + innerR * math.sin(midAngle);
      final nextOuterX = center.dx + outerR * math.cos(nextAngle);
      final nextOuterY = center.dy + outerR * math.sin(nextAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      }
      path.quadraticBezierTo(innerX, innerY, nextOuterX, nextOuterY);
    }
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    canvas.drawCircle(center, radius * 0.15, fill);
    canvas.drawCircle(center, radius * 0.15, stroke);
  }

  void _drawBorderPattern(Canvas canvas, Size size, Paint paint) {
    const step = 20.0;
    const amplitude = 4.0;

    final topPath = Path();
    topPath.moveTo(0, amplitude);
    for (double x = 0; x < size.width; x += step) {
      topPath.quadraticBezierTo(
        x + step / 4, 0,
        x + step / 2, amplitude,
      );
      topPath.quadraticBezierTo(
        x + step * 3 / 4, amplitude * 2,
        x + step, amplitude,
      );
    }
    canvas.drawPath(topPath, paint);

    final bottomPath = Path();
    bottomPath.moveTo(0, size.height - amplitude);
    for (double x = 0; x < size.width; x += step) {
      bottomPath.quadraticBezierTo(
        x + step / 4, size.height,
        x + step / 2, size.height - amplitude,
      );
      bottomPath.quadraticBezierTo(
        x + step * 3 / 4, size.height - amplitude * 2,
        x + step, size.height - amplitude,
      );
    }
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant UzbekPatternPainter oldDelegate) =>
      color != oldDelegate.color || opacity != oldDelegate.opacity;
}

class UzbekPatternOverlay extends StatelessWidget {
  final Color color;
  final double opacity;

  const UzbekPatternOverlay({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: UzbekPatternPainter(color: color, opacity: opacity),
      ),
    );
  }
}
