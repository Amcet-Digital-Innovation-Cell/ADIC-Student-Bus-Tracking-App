import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import 'bus_icon_widget.dart';
import 'theme_controller.dart';

class StopsBottomSheet extends StatefulWidget {
  final BusRouteModel bus;
  final bool isEveningReturn;

  const StopsBottomSheet({
    super.key,
    required this.bus,
    required this.isEveningReturn,
  });

  @override
  State<StopsBottomSheet> createState() => _StopsBottomSheetState();
}

class _StopsBottomSheetState extends State<StopsBottomSheet>
    with TickerProviderStateMixin {
  late final AnimationController _dropController;
  late final AnimationController _pulseController;

  static const double _rowHeight = 64.0;
  static const double _ropeCenterX = 24.0;

  @override
  void initState() {
    super.initState();

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dropController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkMode,
      builder: (context, isDark, _) {
        final List<String> currentStops =
            widget.bus.getStops(widget.isEveningReturn);
        final int totalStops = currentStops.length;
        final double listTotalHeight = totalStops * _rowHeight;

        final Color sheetBg = isDark ? const Color(0xFF041224) : Colors.white;
        final Color titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final Color knotCyan =
            isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7);

        final Color badgeBg = isDark
            ? const Color(0xFF002244)
            : const Color(0xFFE2E8F0);

        final Color badgeText = isDark
            ? const Color(0xFF38BDF8)
            : const Color(0xFF0369A1);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Container(
            color: sheetBg,
            child: Stack(
              children: [
                // 1. Ambient Live Tracking Surface (Radar rings & 3D GPS beads on plain area)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SheetAmbiencePainter(isDark: isDark),
                  ),
                ),

                // 2. Dynamic Parallax Background Wave Peaks (Reacts to dismissal drag)
                AnimatedBuilder(
                  animation: ModalRoute.of(context)?.animation ??
                      kAlwaysCompleteAnimation,
                  builder: (context, _) {
                    final double openProgress =
                        ModalRoute.of(context)?.animation?.value ?? 1.0;
                    final double dragDownRatio =
                        (1.0 - openProgress).clamp(0.0, 1.0);

                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 215,
                      child: CustomPaint(
                        painter: _BottomSheetPeaksPainter(
                          isDark: isDark,
                          dragOffsetRatio: dragDownRatio,
                        ),
                      ),
                    );
                  },
                ),

                // 3. Foreground Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.20)
                                : Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header: Contoured Bus Profile, Route Name & Interactive Neon Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              NeumorphicBusIcon(
                                size: 46,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.bus.routeName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.bus.busNo,
                                      style: TextStyle(
                                        color: badgeText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _InteractiveNeonCloseButton(
                            isDark: isDark,
                            iconColor: titleColor,
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Timeline Container
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.50,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            height: listTotalHeight + 12,
                            child: Stack(
                              children: [
                                // Dropping Rope and Knots
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge(
                                        [_dropController, _pulseController]),
                                    builder: (context, _) {
                                      return CustomPaint(
                                        painter: _RopeDropKnotPainter(
                                          progress: _dropController.value,
                                          pulse: _pulseController.value,
                                          totalStops: totalStops,
                                          rowHeight: _rowHeight,
                                          ropeX: _ropeCenterX,
                                          ropeColor: knotCyan,
                                          isDark: isDark,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Staggered Stop Names
                                ...List.generate(totalStops, (index) {
                                  final stopName = currentStops[index];
                                  final isStart = index == 0;
                                  final isFinal = index == totalStops - 1;

                                  final double knotTime =
                                      (index / totalStops).clamp(0.0, 0.95);
                                  final double labelEndTime =
                                      (knotTime + 0.18).clamp(0.0, 1.0);

                                  final Animation<double> labelAnim =
                                      CurvedAnimation(
                                    parent: _dropController,
                                    curve: Interval(knotTime, labelEndTime,
                                        curve: Curves.easeOutCubic),
                                  );

                                  return Positioned(
                                    top: index * _rowHeight,
                                    left: _ropeCenterX + 24.0,
                                    right: 0,
                                    height: _rowHeight,
                                    child: AnimatedBuilder(
                                      animation: labelAnim,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: labelAnim.value,
                                          child: Transform.translate(
                                            offset: Offset(
                                                16.0 * (1.0 - labelAnim.value),
                                                0),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            stopName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: titleColor,
                                            ),
                                          ),
                                          if (isStart || isFinal)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2.0),
                                              child: Text(
                                                isStart
                                                    ? 'Start point'
                                                    : 'Final terminal',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: knotCyan,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ambient live tracking surface: Soft radial glow, carved radar rings,
/// and raised 3D GPS beads across the upper plain area of the sheet.
class _SheetAmbiencePainter extends CustomPainter {
  final bool isDark;

  const _SheetAmbiencePainter({required this.isDark});

  static const List<List<double>> _dots = [
    [0.12, 0.08, 1.6, 0],
    [0.22, 0.20, 1.4, 0],
    [0.34, 0.06, 1.8, 1],
    [0.48, 0.17, 1.3, 0],
    [0.60, 0.05, 1.5, 0],
    [0.72, 0.19, 1.7, 1],
    [0.84, 0.09, 1.3, 0],
    [0.92, 0.22, 1.6, 0],
    [0.16, 0.34, 1.2, 0],
    [0.65, 0.32, 1.4, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final Rect rect = Rect.fromLTWH(0, 0, w, h);

    // 1. Soft Radial Glow
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.6, -0.9),
          radius: 1.3,
          colors: [
            (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0073A8))
                .withValues(alpha: isDark ? 0.08 : 0.05),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // 2. Embossed Contour Rings
    final Offset origin = Offset(w * 0.92, -h * 0.04);
    for (int i = 0; i < 5; i++) {
      final double radius = w * 0.20 + i * (w * 0.17);
      final double baseOpacity = 0.045 + i * 0.010;
      canvas.drawCircle(
        origin.translate(0.6, 0.6),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.black
              .withValues(alpha: baseOpacity * (isDark ? 1.0 : 0.4)),
      );
      canvas.drawCircle(
        origin.translate(-0.6, -0.6),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white
              .withValues(alpha: baseOpacity * (isDark ? 0.9 : 1.2)),
      );
    }

    // 3. Glossy 3D GPS Beads
    for (final dot in _dots) {
      _drawBead(canvas, Offset(w * dot[0], h * dot[1]), dot[2],
          hero: dot[3] == 1);
    }
  }

  void _drawBead(Canvas canvas, Offset pos, double r, {required bool hero}) {
    final Color base = hero
        ? const Color(0xFF00E5FF)
        : (isDark ? Colors.white : const Color(0xFF041224));
    final double bodyRadius = r * (hero ? 1.4 : 1.0);

    if (hero) {
      canvas.drawCircle(
        pos,
        bodyRadius * 3.0,
        Paint()
          ..color = base.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: pos.translate(bodyRadius * 0.5, bodyRadius * 0.8),
        width: bodyRadius * 2.2,
        height: bodyRadius * 0.9,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.30 : 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, bodyRadius * 0.6),
    );

    final Rect sphereRect = Rect.fromCircle(center: pos, radius: bodyRadius);
    canvas.drawCircle(
      pos,
      bodyRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.6),
          radius: 1.0,
          colors: [
            Color.lerp(base, Colors.white, hero ? 0.7 : 0.5)!,
            base,
            Color.lerp(base, Colors.black, hero ? 0.2 : 0.35)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(sphereRect)
        ..isAntiAlias = true,
    );

    canvas.drawCircle(
      pos.translate(-bodyRadius * 0.35, -bodyRadius * 0.4),
      bodyRadius * 0.35,
      Paint()..color = Colors.white.withValues(alpha: hero ? 0.85 : 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _SheetAmbiencePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Custom Vector Painter rendering the 4-layer peaks graphic across the bottom
/// with real-time parallax downward retreat during bottom-sheet dismissal drags.
class _BottomSheetPeaksPainter extends CustomPainter {
  final bool isDark;
  final double dragOffsetRatio;

  const _BottomSheetPeaksPainter({
    required this.isDark,
    this.dragOffsetRatio = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Color layer1 = isDark
        ? const Color(0xFF003852).withValues(alpha: 0.18)
        : const Color(0xFF00D2FF).withValues(alpha: 0.06);
    final Color layer2 = isDark
        ? const Color(0xFF004D70).withValues(alpha: 0.24)
        : const Color(0xFF00A3E0).withValues(alpha: 0.10);
    final Color layer3 = isDark
        ? const Color(0xFF00618C).withValues(alpha: 0.32)
        : const Color(0xFF0077A8).withValues(alpha: 0.15);
    final Color layer4 = isDark
        ? const Color(0xFF002238).withValues(alpha: 0.45)
        : const Color(0xFF00537A).withValues(alpha: 0.22);

    final double shift1 = dragOffsetRatio * (h * 0.70);
    final double shift2 = dragOffsetRatio * (h * 0.90);
    final double shift3 = dragOffsetRatio * (h * 1.15);
    final double shift4 = dragOffsetRatio * (h * 1.45);

    // Layer 1
    final Path path1 = Path()
      ..moveTo(0, (h * 0.44) + shift1)
      ..lineTo(w * 0.15, (h * 0.57) + shift1)
      ..lineTo(w * 0.42, (h * 0.62) + shift1)
      ..lineTo(w * 0.58, (h * 0.40) + shift1)
      ..lineTo(w * 0.82, (h * 0.52) + shift1)
      ..lineTo(w, (h * 0.32) + shift1)
      ..lineTo(w, h + shift1)
      ..lineTo(0, h + shift1)
      ..close();
    canvas.drawPath(path1, Paint()..color = layer1);

    // Layer 2
    final Path path2 = Path()
      ..moveTo(0, (h * 0.60) + shift2)
      ..lineTo(w * 0.18, (h * 0.68) + shift2)
      ..lineTo(w * 0.40, (h * 0.64) + shift2)
      ..lineTo(w * 0.62, (h * 0.50) + shift2)
      ..lineTo(w * 0.88, (h * 0.60) + shift2)
      ..lineTo(w, (h * 0.48) + shift2)
      ..lineTo(w, h + shift2)
      ..lineTo(0, h + shift2)
      ..close();
    canvas.drawPath(path2, Paint()..color = layer2);

    // Layer 3
    final Path path3 = Path()
      ..moveTo(0, (h * 0.72) + shift3)
      ..lineTo(w * 0.16, (h * 0.77) + shift3)
      ..lineTo(w * 0.35, (h * 0.74) + shift3)
      ..lineTo(w * 0.64, (h * 0.62) + shift3)
      ..lineTo(w * 0.75, (h * 0.70) + shift3)
      ..lineTo(w, (h * 0.64) + shift3)
      ..lineTo(w, h + shift3)
      ..lineTo(0, h + shift3)
      ..close();
    canvas.drawPath(path3, Paint()..color = layer3);

    // Layer 4
    final Path path4 = Path()
      ..moveTo(0, (h * 0.80) + shift4)
      ..lineTo(w * 0.28, (h * 0.86) + shift4)
      ..lineTo(w * 0.52, (h * 0.82) + shift4)
      ..lineTo(w * 0.75, (h * 0.80) + shift4)
      ..lineTo(w, (h * 0.76) + shift4)
      ..lineTo(w, h + shift4)
      ..lineTo(0, h + shift4)
      ..close();
    canvas.drawPath(path4, Paint()..color = layer4);
  }

  @override
  bool shouldRepaint(covariant _BottomSheetPeaksPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.dragOffsetRatio != dragOffsetRatio;
}

/// Canvas Painter executing the falling timeline rope and knots
class _RopeDropKnotPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final int totalStops;
  final double rowHeight;
  final double ropeX;
  final Color ropeColor;
  final bool isDark;

  const _RopeDropKnotPainter({
    required this.progress,
    required this.pulse,
    required this.totalStops,
    required this.rowHeight,
    required this.ropeX,
    required this.ropeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalStops <= 0) return;

    final double firstStopY = rowHeight * 0.50;
    final double maxRopeLength = (totalStops - 1) * rowHeight;
    final double currentRopeLength = maxRopeLength * progress;
    final double currentTipY = firstStopY + currentRopeLength;

    // 1. Ghost Guide Line
    final Paint ghostRopePaint = Paint()
      ..color = (isDark ? Colors.white12 : Colors.black12)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(ropeX, firstStopY),
      Offset(ropeX, firstStopY + maxRopeLength),
      ghostRopePaint,
    );

    // 2. Active Dropping Neon Rope
    if (progress > 0.0) {
      final Paint activeRopePaint = Paint()
        ..color = ropeColor.withValues(alpha: 0.9)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(ropeX, firstStopY),
        Offset(ropeX, currentTipY),
        activeRopePaint,
      );
    }

    // 3. Knots and Waypoint Rings
    for (int i = 0; i < totalStops; i++) {
      final double knotY = firstStopY + (i * rowHeight);
      final double knotTrigger = i / totalStops;
      final bool isStart = i == 0;
      final bool isFinal = i == totalStops - 1;

      if (progress >= knotTrigger) {
        final double knotProgress =
            ((progress - knotTrigger) / 0.15).clamp(0.0, 1.0);
        final double scale = _elasticOut(knotProgress);

        if (isStart) {
          final double glowRadius = 9.0 + (pulse * 4.0);
          final Paint pulsePaint = Paint()
            ..color = ropeColor.withValues(alpha: 0.30 * (1.0 - pulse * 0.4))
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(ropeX, knotY), glowRadius, pulsePaint);
        }

        final Paint knotPaint = Paint()
          ..color = ropeColor
          ..style = (isStart || isFinal)
              ? PaintingStyle.fill
              : PaintingStyle.stroke
          ..strokeWidth = 2.4;

        canvas.drawCircle(Offset(ropeX, knotY), 5.5 * scale, knotPaint);

        if (!isStart && !isFinal) {
          final Paint innerCore = Paint()
            ..color = isDark ? const Color(0xFF041224) : Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(ropeX, knotY), 3.2 * scale, innerCore);
        }
      }
    }
  }

  double _elasticOut(double t) {
    if (t == 0.0 || t == 1.0) return t;
    return (1.0 + (1.0 - t) * (1.0 - t) * (1.0 - t)) *
        (1.0 - (1.0 - t) * (1.0 - t));
  }

  @override
  bool shouldRepaint(covariant _RopeDropKnotPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.isDark != isDark;
}

/// Interactive circular button updated with full mobile touch responsiveness
/// (pan down, drag tracking, decay animation) matching the tracking page cards.
class _InteractiveNeonCloseButton extends StatefulWidget {
  final bool isDark;
  final Color iconColor;
  final VoidCallback onTap;

  const _InteractiveNeonCloseButton({
    required this.isDark,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_InteractiveNeonCloseButton> createState() =>
      _InteractiveNeonCloseButtonState();
}

class _InteractiveNeonCloseButtonState
    extends State<_InteractiveNeonCloseButton>
    with SingleTickerProviderStateMixin {
  Offset? _touchPosition;
  late final AnimationController _decayController;
  late final Animation<double> _glowIntensity;

  @override
  void initState() {
    super.initState();
    _decayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _glowIntensity = CurvedAnimation(
      parent: _decayController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _decayController.dispose();
    super.dispose();
  }

  void _activateGlow(Offset localPos) {
    setState(() => _touchPosition = localPos);
    _decayController.stop();
    _decayController.value = 1.0;
  }

  void _releaseGlow() {
    _decayController.reverse(from: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonBg = widget.isDark
        ? const Color(0xFF0B223D)
        : const Color(0xFFEDF2F7);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (e) => _activateGlow(e.localPosition),
      onHover: (e) => setState(() => _touchPosition = e.localPosition),
      onExit: (_) => _releaseGlow(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanDown: (details) => _activateGlow(details.localPosition),
        onPanUpdate: (details) =>
            setState(() => _touchPosition = details.localPosition),
        onPanEnd: (_) => _releaseGlow(),
        onPanCancel: () => _releaseGlow(),
        child: AnimatedBuilder(
          animation: _glowIntensity,
          builder: (context, child) {
            final double intensity = _glowIntensity.value;

            return Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: buttonBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: widget.isDark ? 0.35 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  if (intensity > 0.01)
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(
                        alpha: (widget.isDark ? 0.45 : 0.28) * intensity,
                      ),
                      blurRadius: 10 + (4 * intensity),
                      spreadRadius: 1.0 * intensity,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NeonCircleButtonPainter(
                        touchPosition: _touchPosition,
                        intensity: intensity,
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.close_rounded,
                    color: intensity > 0.1
                        ? const Color(0xFF00E5FF)
                        : widget.iconColor,
                    size: 18,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NeonCircleButtonPainter extends CustomPainter {
  final Offset? touchPosition;
  final double intensity;
  final bool isDark;

  const _NeonCircleButtonPainter({
    required this.touchPosition,
    required this.intensity,
    required this.isDark,
  });

  static const List<Color> _darkPalette = [
    Color(0xFFE0FFFF),
    Color(0xFF00F0FF),
    Color(0xFF0088FF),
    Colors.transparent,
  ];

  static const List<Color> _lightPalette = [
    Color(0xFFFFFFFF),
    Color(0xFF00B4D8),
    Color(0xFF0077B6),
    Colors.transparent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 0.8;

    // Base subtle border outline
    final baseBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08);

    canvas.drawCircle(center, radius, baseBorderPaint);

    // Active touch glow matching tracking screen neon painter
    if (intensity > 0.01 && touchPosition != null) {
      final pos = touchPosition!;
      final Alignment centerAlignment = Alignment(
        (pos.dx / size.width) * 2 - 1,
        (pos.dy / size.height) * 2 - 1,
      );

      final auraShader = RadialGradient(
        center: centerAlignment,
        radius: 0.85,
        colors: [
          (isDark ? const Color(0xFF00F0FF) : const Color(0xFF0284C7))
              .withValues(alpha: (isDark ? 0.25 : 0.16) * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, Paint()..shader = auraShader);

      final borderShader = RadialGradient(
        center: centerAlignment,
        radius: 1.2,
        colors: isDark ? _darkPalette : _lightPalette,
        stops: const [0.0, 0.25, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      final neonPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isDark ? 2.4 : 2.0) * intensity
        ..shader = borderShader;

      canvas.drawCircle(center, radius, neonPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonCircleButtonPainter oldDelegate) {
    return oldDelegate.touchPosition != touchPosition ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isDark != isDark;
  }
}