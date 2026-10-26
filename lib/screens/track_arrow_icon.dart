import 'package:flutter/material.dart';
import 'dart:ui' as ui;
class TrackArrowIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TrackArrowIcon({
    super.key,
    this.size = 13.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrackArrowPainter(color: color),
      ),
    );
  }
}

class _TrackArrowPainter extends CustomPainter {
  final Color color;

  const _TrackArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    // Aerodynamic forward-pointing chevron path
    final ui.Path path = ui.Path()
      ..moveTo(0.0, h * 0.08)           // Upper left notch wing tip
      ..lineTo(w * 0.95, h * 0.50)    // Leading forward dart point
      ..lineTo(0.0, h * 0.92)           // Lower left notch wing tip
      ..lineTo(w * 0.35, h * 0.50)    // Inward concave center fold
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrackArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}