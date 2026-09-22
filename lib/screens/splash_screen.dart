import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _textAnimController;
  late final AnimationController _neonGlowController;
  late final Animation<double> _glowAnimation;

  static const Color _navyBackground = Color(0xFF070E18);
  static const Color _homeRoyalBlue = Color(0xFF005175);
  static const Color _homeDeepNavy = Color(0xFF06101E);

  @override
  void initState() {
    super.initState();
    // Entry text reveals
    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Continuous breathing neon glow controller
    _neonGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _neonGlowController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _textAnimController.dispose();
    _neonGlowController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredText({
    required Widget child,
    required double startInterval,
    required double endInterval,
  }) {
    final animation = CurvedAnimation(
      parent: _textAnimController,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 24.0 * (1.0 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _navyBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _navyBackground,
        body: Stack(
          children: [
            // Dark Layered Bevel Panels with Continuous Pulsing Neon Glow Slits
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _NeonSlitLogoFramePainter(
                      glowFactor: _glowAnimation.value,
                    ),
                  );
                },
              ),
            ),

            // Main Content
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),
                    const SizedBox(height: 11),

                    // Center Logo
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 210,
                        height: 210,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.directions_bus_rounded,
                          size: 70,
                          color: Colors.amber,
                        ),
                      ),
                    ),

                    const SizedBox(height: 98),

                    // 1. Primary Title Reveal
                    _buildStaggeredText(
                      startInterval: 0.15,
                      endInterval: 0.60,
                      child: const Text(
                        ' AMCET BUS TRACKING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.2,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 2. Subtitle College Name Reveal
                    _buildStaggeredText(
                      startInterval: 0.30,
                      endInterval: 0.75,
                      child: const Text(
                        ' Annai Mira College of Engineering & Technology',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFBACFE6),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Version Tag Pill Reveal
                    _buildStaggeredText(
                      startInterval: 0.45,
                      endInterval: 0.88,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: _homeDeepNavy.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Text(
                          'VERSION 1.0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: Color(0xFF7DD3FC),
                            fontSize: 9.5,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 4. Attribution Tag Reveal
                    _buildStaggeredText(
                      startInterval: 0.58,
                      endInterval: 1.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DESIGNED BY',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 8.5,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: _homeRoyalBlue.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'ADIC',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Color.fromARGB(255, 47, 193, 255),
                                fontSize: 10.5,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: Color.fromARGB(55, 0, 229, 255),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Frosted Glassmorphic Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              offset: const Offset(0, 8),
                              blurRadius: 18,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                              offset: const Offset(0, -1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.14),
                                    Colors.white.withValues(alpha: 0.04),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(26),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      smoothPageRoute(page: const HomeScreen()),
                                    );
                                  },
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Get Started',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color.fromARGB(198, 255, 255, 255),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Color.fromARGB(207, 255, 255, 255),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonSlitLogoFramePainter extends CustomPainter {
  final double glowFactor;

  const _NeonSlitLogoFramePainter({this.glowFactor = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Dark base background plate
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F1A2A),
          Color(0xFF08101C),
          Color(0xFF040810),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // --- TOP SECTOR PANELS & SEAMS ---

    // Plate A: Top-left wedge framing top of logo
    final Path topPlateLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.40, 0)
      ..lineTo(0, h * 0.38)
      ..close();
    _drawPanel(
      canvas,
      topPlateLeft,
      start: Offset.zero,
      end: Offset(w * 0.40, h * 0.38),
      topColor: const Color(0xFF142133),
      bottomColor: const Color(0xFF0B1420),
    );
    _drawGlowingNeonLine(
      canvas,
      Offset(w * 0.40, 0),
      Offset(0, h * 0.38),
      baseIntensity: 0.90,
    );

    // Plate B: Top sector wedge cutting downward from top right
    final Path topPlateRight = Path()
      ..moveTo(w * 0.65, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w * 0.18, h * 0.46)
      ..close();
    _drawPanel(
      canvas,
      topPlateRight,
      start: Offset(w, 0),
      end: Offset(w * 0.18, h * 0.46),
      topColor: const Color(0xFF132032),
      bottomColor: const Color(0xFF09121E),
    );
    _drawGlowingNeonLine(
      canvas,
      Offset(w, h * 0.25),
      Offset(w * 0.18, h * 0.46),
      baseIntensity: 0.85,
    );

    // Subtle upper top-right accent slit
    _drawGlowingNeonLine(
      canvas,
      Offset(w * 0.85, 0),
      Offset(w * 0.50, h * 0.26),
      baseIntensity: 0.60,
    );

    // --- BOTTOM SECTOR PANELS & NON-INTERFERING SEAMS ---

    // Plate C: Lower-left blade framing the bottom-left edge
    final Path bottomPlateLeft = Path()
      ..moveTo(0, h * 0.60)
      ..lineTo(w * 0.28, h * 0.65)
      ..lineTo(0, h)
      ..close();
    _drawPanel(
      canvas,
      bottomPlateLeft,
      start: Offset(0, h * 0.60),
      end: Offset(0, h),
      topColor: const Color(0xFF0E1A29),
      bottomColor: const Color(0xFF060E18),
    );
    _drawGlowingNeonLine(
      canvas,
      Offset(0, h * 0.60),
      Offset(w * 0.28, h * 0.65),
      baseIntensity: 0.80,
    );

    // Plate D: Steep lower center panel cutting to bottom left
    final Path bottomPlateMid = Path()
      ..moveTo(w * 0.42, h * 0.52)
      ..lineTo(w * 0.28, h * 0.65)
      ..lineTo(w * 0.15, h)
      ..lineTo(0, h)
      ..lineTo(0, h * 0.85)
      ..close();
    _drawPanel(
      canvas,
      bottomPlateMid,
      start: Offset(w * 0.42, h * 0.52),
      end: Offset(0, h),
      topColor: const Color(0xFF0B1624),
      bottomColor: const Color(0xFF040A12),
    );
    _drawGlowingNeonLine(
      canvas,
      Offset(w * 0.42, h * 0.52),
      Offset(w * 0.15, h),
      baseIntensity: 0.75,
    );

    // Plate E: Lower right base panel
    final Path bottomPlateRightBase = Path()
      ..moveTo(w * 0.42, h * 0.52)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h)
      ..lineTo(w * 0.15, h)
      ..close();
    _drawPanel(
      canvas,
      bottomPlateRightBase,
      start: Offset(w * 0.42, h * 0.52),
      end: Offset(w, h),
      topColor: const Color(0xFF101E30),
      bottomColor: const Color(0xFF070F1A),
    );

    // Static lower-right perimeter edge accent
    _drawGlowingNeonLine(
      canvas,
      Offset(w * 0.65, h),
      Offset(w, h * 0.74),
      baseIntensity: 0.70,
    );
  }

  void _drawPanel(
    Canvas canvas,
    Path path, {
    required Offset start,
    required Offset end,
    required Color topColor,
    required Color bottomColor,
  }) {
    canvas.drawPath(
      path.shift(const Offset(3.5, 6.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.82)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment(
          (start.dx / 400.0) * 2 - 1,
          (start.dy / 800.0) * 2 - 1,
        ),
        end: Alignment(
          (end.dx / 400.0) * 2 - 1,
          (end.dy / 800.0) * 2 - 1,
        ),
        colors: [topColor, bottomColor],
      ).createShader(path.getBounds());
    canvas.drawPath(path, fill);
  }

  void _drawGlowingNeonLine(
    Canvas canvas,
    Offset start,
    Offset end, {
    double baseIntensity = 1.0,
  }) {
    final Rect lineBounds = Rect.fromPoints(start, end);

    final double pulse = 0.75 + (glowFactor * 0.45);
    final double currentIntensity = (baseIntensity * pulse).clamp(0.0, 1.0);
    final double blurSigma = 2.5 + (glowFactor * 3.5);
    final double outerStrokeWidth = 3.5 + (glowFactor * 2.5);

    // 1. Soft pulsing outer neon halo bloom
    final Paint neonAtmosphere = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.50 * currentIntensity),
          const Color(0xFF00B4D8).withValues(alpha: 0.35 * currentIntensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(lineBounds)
      ..strokeWidth = outerStrokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawLine(start, end, neonAtmosphere);

    // 2. Focused electric cyan neon ribbon
    final Paint neonRibbon = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.95 * currentIntensity),
          const Color(0xFF00B4D8).withValues(alpha: 0.85 * currentIntensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.75, 1.0],
      ).createShader(lineBounds)
      ..strokeWidth = 2.0;
    canvas.drawLine(start, end, neonRibbon);

    // 3. Razor-sharp white filament core
    final Paint whiteCore = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: (0.75 + glowFactor * 0.25) * baseIntensity),
          Colors.white.withValues(alpha: (0.35 + glowFactor * 0.20) * baseIntensity),
          Colors.transparent,
        ],
        stops: const [0.08, 0.42, 0.68, 0.92],
      ).createShader(lineBounds)
      ..strokeWidth = 0.8 + (glowFactor * 0.4);
    canvas.drawLine(start, end, whiteCore);
  }

  @override
  bool shouldRepaint(covariant _NeonSlitLogoFramePainter oldDelegate) {
    return oldDelegate.glowFactor != glowFactor;
  }
}