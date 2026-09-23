import 'package:flutter/material.dart';
import 'theme_controller.dart';

class NeumorphicBusIcon extends StatelessWidget {
  final double size;
  final bool isDark;

  const NeumorphicBusIcon({
    super.key,
    this.size = 46,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDark ? AppTheme.accentCyan : AppTheme.cyanBlue;
    final Color bgColor = isDark ? const Color(0xFF071526) : AppTheme.bgSurface(false);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: AppTheme.neumorphicShadows(isDark, depth: 3.5, blur: 6),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.58,
          height: size * 0.58,
          child: CustomPaint(
            painter: _BusBoardingPainter(color: iconColor, isDark: isDark),
          ),
        ),
      ),
    );
  }
}

class _BusBoardingPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _BusBoardingPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // Passenger Silhouette
    canvas.drawCircle(Offset(w * 0.12, h * 0.32), w * 0.085, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.09, h * 0.42),
        const Radius.circular(2),
      ),
      fill,
    );

    // Main Bus Body
    final busRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.10, w * 0.68, h * 0.72),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(busRect, fill);

    // Windshield Cutout
    final Paint mask = Paint()..color = isDark ? const Color(0xFF071526) : Colors.white;
    final windshield = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.36, h * 0.22, w * 0.52, h * 0.24),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(windshield, mask);

    // Center divider
    canvas.drawLine(
      Offset(w * 0.62, h * 0.22),
      Offset(w * 0.62, h * 0.46),
      Paint()
        ..color = color
        ..strokeWidth = w * 0.04,
    );

    // Top Bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, h * 0.14, w * 0.40, h * 0.05),
        const Radius.circular(1),
      ),
      mask,
    );

    // Headlights
    canvas.drawCircle(Offset(w * 0.40, h * 0.62), w * 0.05, mask);
    canvas.drawCircle(Offset(w * 0.84, h * 0.62), w * 0.05, mask);

    // Wheels
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.80, w * 0.14, h * 0.15),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.74, h * 0.80, w * 0.14, h * 0.15),
        const Radius.circular(3),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}