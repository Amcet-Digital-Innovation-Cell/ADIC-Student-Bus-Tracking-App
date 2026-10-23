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
    final Color iconColor = isDark ? const Color.fromARGB(255, 244, 245, 247) : AppTheme.cyanBlue;
    final Color bgColor = isDark ? const Color.fromARGB(255, 16, 48, 89) : AppTheme.bgSurface(false);

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

class NeumorphicBusaloneIcon extends StatelessWidget {
  final double size;
  final bool isDark;

  const NeumorphicBusaloneIcon({
    super.key,
    this.size = 46,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDark ? const Color.fromARGB(255, 244, 245, 247) : AppTheme.cyanBlue;
    final Color bgColor = isDark ? const Color.fromARGB(255, 16, 48, 89) : AppTheme.bgSurface(false);

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
            painter: _BusiconPainter(color: iconColor, isDark: isDark),
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

class _BusiconPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _BusiconPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint mask = Paint()
      ..color = isDark ? const Color(0xFF071526) : Colors.white
      ..style = PaintingStyle.fill;

    // 1. Wheels (Placed underneath, centered symmetrically at x = 0.50 * w)
    // Left wheel: [0.26w to 0.40w], Right wheel: [0.60w to 0.74w]
    final double wheelW = w * 0.14;
    final double wheelH = h * 0.14;
    final double wheelY = h * 0.76;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, wheelY, wheelW, wheelH),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.60, wheelY, wheelW, wheelH),
        const Radius.circular(3),
      ),
      fill,
    );

    // 2. Main Bus Body (Width: 0.64w, centered from 0.18w to 0.82w)
    final double bodyW = w * 0.64;
    final double bodyH = h * 0.70;
    final busRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.10, bodyW, bodyH),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(busRect, fill);

    // 3. Destination Sign / Top Bar (Width: 0.38w, centered from 0.31w to 0.69w)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.31, h * 0.14, w * 0.38, h * 0.05),
        const Radius.circular(1.5),
      ),
      mask,
    );

    // 4. Windshield Cutout (Width: 0.50w, centered from 0.25w to 0.75w)
    final windshield = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.25, h * 0.22, w * 0.50, h * 0.24),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(windshield, mask);

    // 5. Center Window Divider (Exactly on midpoint x = 0.50 * w)
    canvas.drawLine(
      Offset(w * 0.50, h * 0.22),
      Offset(w * 0.50, h * 0.46),
      Paint()
        ..color = color
        ..strokeWidth = w * 0.035,
    );

    // 6. Headlights (Equidistant from center: x = 0.33w and x = 0.67w)
    final double lightRadius = w * 0.045;
    final double lightY = h * 0.62;
    canvas.drawCircle(Offset(w * 0.33, lightY), lightRadius, mask);
    canvas.drawCircle(Offset(w * 0.67, lightY), lightRadius, mask);
  }

  @override
  bool shouldRepaint(covariant _BusiconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}