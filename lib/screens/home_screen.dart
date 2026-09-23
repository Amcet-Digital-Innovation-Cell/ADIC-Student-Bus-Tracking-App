import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../services/api_service.dart';
import 'tracking_screen.dart';
import 'stops_bottom_sheet.dart';
import 'bus_icon_widget.dart';
import 'theme_controller.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class AnimatedHeaderBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;

  const AnimatedHeaderBackground({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  State<AnimatedHeaderBackground> createState() =>
      _AnimatedHeaderBackgroundState();
}

class _AnimatedHeaderBackgroundState extends State<AnimatedHeaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _HeaderTelemetryMotionPainter(
            progress: _waveController.value,
            isDark: widget.isDark,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _HeaderTelemetryMotionPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _HeaderTelemetryMotionPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final double phase = progress * 2 * math.pi;

    final double auraCenterX = w * (0.35 + 0.3 * math.sin(phase * 0.5));
    final double auraCenterY = h * (0.30 + 0.2 * math.cos(phase * 0.5));

    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final auraShader = RadialGradient(
      center: Alignment(
        (auraCenterX / w) * 2 - 1,
        (auraCenterY / h) * 2 - 1,
      ),
      radius: 1.1,
      colors: [
        (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
            .withValues(alpha: isDark ? 0.15 : 0.08),
        (isDark ? const Color(0xFF0369A1) : const Color(0xFF38BDF8))
            .withValues(alpha: isDark ? 0.06 : 0.03),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = auraShader);

    final Path wavePath1 = Path();
    final double amp1 = 14.0;
    final double midY1 = h * 0.55;

    for (double x = 0; x <= w; x += 4.0) {
      final double y =
          midY1 + math.sin((x / w * 2.2 * math.pi) + phase) * amp1;
      if (x == 0) {
        wavePath1.moveTo(x, y);
      } else {
        wavePath1.lineTo(x, y);
      }
    }

    final Paint wavePaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = ui.Gradient.linear(
        Offset(0, midY1),
        Offset(w, midY1),
        [
          Colors.transparent,
          (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
              .withValues(alpha: isDark ? 0.35 : 0.20),
          (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
              .withValues(alpha: isDark ? 0.45 : 0.25),
          Colors.transparent,
        ],
        const [0.0, 0.25, 0.75, 1.0],
      );

    canvas.drawPath(wavePath1, wavePaint1);

    final Path wavePath2 = Path();
    final double amp2 = 9.0;
    final double midY2 = h * 0.42;

    for (double x = 0; x <= w; x += 4.0) {
      final double y =
          midY2 + math.cos((x / w * 3.0 * math.pi) - (phase * 1.2)) * amp2;
      if (x == 0) {
        wavePath2.moveTo(x, y);
      } else {
        wavePath2.lineTo(x, y);
      }
    }

    final Paint wavePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1))
          .withValues(alpha: isDark ? 0.16 : 0.09);

    canvas.drawPath(wavePath2, wavePaint2);

    const List<double> nodeOffsets = [0.22, 0.58, 0.82];
    for (int i = 0; i < nodeOffsets.length; i++) {
      final double normX = (nodeOffsets[i] + (progress * 0.2)) % 1.0;
      final double nodeX = w * normX;
      final double nodeY =
          midY1 + math.sin((nodeX / w * 2.2 * math.pi) + phase) * amp1;

      final double pulse =
          (0.5 + 0.5 * math.sin(phase * 2.0 + (i * 1.5))).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(nodeX, nodeY),
        4.0 + (pulse * 3.0),
        Paint()
          ..color = (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
              .withValues(alpha: (0.2 + 0.2 * pulse)),
      );

      canvas.drawCircle(
        Offset(nodeX, nodeY),
        2.0,
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.9)
              : const Color(0xFF0284C7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderTelemetryMotionPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

class AutoScrollStopText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const AutoScrollStopText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.left,
  });

  @override
  State<AutoScrollStopText> createState() => _AutoScrollStopTextState();
}

class _AutoScrollStopTextState extends State<AutoScrollStopText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  AnimationController? _animController;
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkOverflowAndAnimate());
  }

  @override
  void didUpdateWidget(covariant AutoScrollStopText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkOverflowAndAnimate());
    }
  }

  void _checkOverflowAndAnimate() {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 1.0) {
      if (!_isOverflowing) {
        setState(() => _isOverflowing = true);
      }
      _startMarqueeAnimation(maxScroll);
    } else {
      if (_isOverflowing) {
        setState(() => _isOverflowing = false);
      }
      _animController?.stop();
    }
  }

  void _startMarqueeAnimation(double maxScroll) {
    _animController?.dispose();

    final int durationMs = ((maxScroll + 40) * 35).toInt().clamp(3000, 10000);

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _animController!.addListener(() {
      if (!mounted || !_scrollController.hasClients) return;
      final progress = _animController!.value;
      if (progress <= 0.85) {
        final double scrollVal = (progress / 0.85) * maxScroll;
        _scrollController.jumpTo(scrollVal);
      } else {
        _scrollController.jumpTo(0);
      }
    });

    _animController!.repeat();
  }

  @override
  void dispose() {
    _animController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _isOverflowing ? Colors.transparent : Colors.black,
                Colors.black,
                Colors.black,
                _isOverflowing ? Colors.transparent : Colors.black,
              ],
              stops: const [0.0, 0.08, 0.92, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Text(
                widget.text,
                maxLines: 1,
                softWrap: false,
                textAlign: widget.textAlign,
                style: widget.style,
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final DateTime Function()? timeProvider;

  const HomeScreen({super.key, this.timeProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static final List<BusRouteModel> _fallbackRoutes = [
    BusRouteModel(
      id: '1',
      routeName: 'Sankaranpalayam',
      busNo: 'Bus 10',
      forwardStops: const [
        'Main Bus Stand',
        'Central Market',
        'GH Hospital',
        'Sankaranpalayam',
        'Annai Mira College'
      ],
    ),
    BusRouteModel(
      id: '2',
      routeName: 'Old Bus Stand',
      busNo: 'Bus 10',
      forwardStops: const [
        'Main Bus Stand',
        'Old Bus Stand',
        'Collectorate',
        'GH Hospital',
        'Annai Mira College'
      ],
    ),
    BusRouteModel(
      id: '3',
      routeName: 'Vellore',
      busNo: 'Bus 10',
      forwardStops: const [
        'Main Bus Stand',
        'Vellore',
        'Sipcot',
        'Ranipet',
        'Annai Mira College'
      ],
    ),
    BusRouteModel(
      id: '4',
      routeName: 'Walaja',
      busNo: 'Bus 14',
      forwardStops: const [
        'Walaja Toll',
        'Ranipet',
        'Arcot',
        'Collectorate',
        'Annai Mira College'
      ],
    ),
  ];

  late List<BusRouteModel> _routes;
  late List<BusRouteModel> _filteredRoutes;
  String? _loadErrorMessage;

  bool get _isEveningTime {
    final now = widget.timeProvider?.call() ?? DateTime.now();
    return now.hour >= 12;
  }

  @override
  void initState() {
    super.initState();
    _routes = List.from(_fallbackRoutes);
    _filteredRoutes = List.from(_routes);
    _searchController.addListener(_filterRoutes);
    _searchFocusNode.addListener(() => setState(() {}));
    Future.microtask(_loadRoutes);
  }

  Future<void> _loadRoutes() async {
    final loadedRoutes = await ApiService.fetchRoutes();
    if (!mounted) return;

    setState(() {
      if (loadedRoutes.isNotEmpty) {
        _routes = loadedRoutes;
        _filteredRoutes = List.from(_routes);
        _loadErrorMessage = null;
      } else {
        _routes = List.from(_fallbackRoutes);
        _filteredRoutes = List.from(_routes);
        _loadErrorMessage =
            'Using cached routes while the backend endpoint is unavailable.';
      }
    });
  }

  void _filterRoutes() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRoutes = List.from(_routes);
      } else {
        _filteredRoutes = _routes.where((bus) {
          final matchesBusName = bus.routeName.toLowerCase().contains(query);
          final matchesBusNo = bus.busNo.toLowerCase().contains(query);
          final matchesStop =
              bus.forwardStops.any((stop) => stop.toLowerCase().contains(query));
          return matchesBusName || matchesBusNo || matchesStop;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showStopsModal(BuildContext context, BusRouteModel bus, bool isEvening) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 400),
      ),
      builder: (context) => StopsBottomSheet(
        bus: bus,
        isEveningReturn: isEvening,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEvening = _isEveningTime;

    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkMode,
      builder: (context, isDark, _) {
        final Color headerBg = AppTheme.headerBg(isDark);
        final Color headerTitleColor = AppTheme.headerTextPrimary(isDark);
        final Color headerSubtextColor = AppTheme.headerTextSecondary(isDark);

        final Color sectionBgColor = isDark
            ? const Color(0xFF071B30)
            : const Color(0xFFCFDCED);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppTheme.bgSurface(isDark),
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: AppTheme.bgSurface(isDark),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: headerBg,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _HeaderRouteSignalPainter(isDark: isDark),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF041224)
                                  : const Color.fromARGB(255, 1, 49, 82),
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(32)),
                            ),
                            child: AnimatedHeaderBackground(
                              isDark: isDark,
                              child: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 20, 20, 22),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Where to go?',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 28,
                                                      fontWeight: FontWeight.w900,
                                                      color: headerTitleColor,
                                                      letterSpacing: -0.6,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Track your bus in real-time.',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: headerSubtextColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ThemeToggleButton(isDark: isDark),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      NeonSearchBarContainer(
                                        isDark: isDark,
                                        isFocused: _searchFocusNode.hasFocus,
                                        child: TextField(
                                          focusNode: _searchFocusNode,
                                          controller: _searchController,
                                          onChanged: (val) {
                                            _filterRoutes();
                                          },
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Search bus or stop name...',
                                            hintStyle: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF64748B)
                                                  : const Color(0xFF94A3B8),
                                              fontSize: 13,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search_rounded,
                                              color: _searchFocusNode.hasFocus
                                                  ? const Color(0xFF00E5FF)
                                                  : (isDark
                                                      ? const Color(0xFF64748B)
                                                      : const Color(0xFF94A3B8)),
                                              size: 20,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: sectionBgColor,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.40 : 0.08),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Header row with route count aligned to edge with static neon border glow
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 18.0),
                                  child: Text(
                                    'Available Routes',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary(isDark),
                                    ),
                                  ),
                                ),
                                // Edge-anchored static neon badge
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0A2647)
                                          : const Color(0xFFD8E5F3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.90)
                                            : const Color(0xFF0284C7).withValues(alpha: 0.85),
                                        width: 1.3,
                                      ),
                                      boxShadow: [
                                        // Static Outer Neon Bloom
                                        BoxShadow(
                                          color: isDark
                                              ? const Color(0xFF00E5FF).withValues(alpha: 0.38)
                                              : const Color(0xFF0284C7).withValues(alpha: 0.28),
                                          blurRadius: 10,
                                          spreadRadius: 0.8,
                                        ),
                                        // Specular highlight in light mode
                                        if (!isDark)
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            offset: const Offset(-1.5, -1.5),
                                            blurRadius: 3,
                                          ),
                                      ],
                                    ),
                                    child: Text(
                                      '${_filteredRoutes.length} buses',
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF00E5FF)
                                            : const Color(0xFF026AA3),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_loadErrorMessage != null)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Text(
                                  _loadErrorMessage!,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.orangeAccent
                                        : Colors.redAccent,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _filteredRoutes.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No matching buses or stops found',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color.fromARGB(
                                                  255, 24, 24, 24),
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _filteredRoutes.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final bus = _filteredRoutes[index];
                                        return _AnimatedRouteCard(
                                          key: ValueKey(bus.id),
                                          index: index,
                                          bus: bus,
                                          isDark: isDark,
                                          isEvening: isEvening,
                                          onStopsTap: () => _showStopsModal(
                                              context, bus, isEvening),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedRouteCard extends StatefulWidget {
  final int index;
  final BusRouteModel bus;
  final bool isDark;
  final bool isEvening;
  final VoidCallback onStopsTap;

  const _AnimatedRouteCard({
    super.key,
    required this.index,
    required this.bus,
    required this.isDark,
    required this.isEvening,
    required this.onStopsTap,
  });

  @override
  State<_AnimatedRouteCard> createState() => _AnimatedRouteCardState();
}

class _AnimatedRouteCardState extends State<_AnimatedRouteCard>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideUpAnim;

  late final AnimationController _connectorPulseController;
  late final AnimationController _arrowLaunchController;
  late final Animation<double> _arrowLaunchAnim;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideUpAnim = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    ));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _animController.forward();
    });

    _connectorPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _arrowLaunchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _arrowLaunchAnim = Tween<double>(begin: 0.0, end: 32.0).animate(
      CurvedAnimation(
        parent: _arrowLaunchController,
        curve: Curves.easeInQuad,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _connectorPulseController.dispose();
    _arrowLaunchController.dispose();
    super.dispose();
  }

  Future<void> _handleTrackTap() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    await _arrowLaunchController.forward();
    if (!mounted) return;

    await Navigator.push(
      context,
      smoothPageRoute(
        page: TrackingScreen(
          bus: widget.bus,
          isEveningReturn: widget.isEvening,
        ),
      ),
    );

    if (mounted) {
      _arrowLaunchController.reset();
      setState(() => _isNavigating = false);
    }
  }

  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle stopTextStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: widget.isDark ? Colors.white70 : Colors.black87,
    );

    final String firstStop = widget.bus.forwardStops.first;
    final String lastStop = widget.bus.forwardStops.last;

    return SlideTransition(
      position: _slideUpAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(widget.isDark),
            borderRadius: BorderRadius.circular(26),
            boxShadow:
                AppTheme.neumorphicShadows(widget.isDark, depth: 8, blur: 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeumorphicBusIcon(
                    size: 46,
                    isDark: widget.isDark,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bus.routeName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(widget.isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.darkNavy,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.bus.busNo,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 248, 249, 249),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.bus.forwardStops.length} stops',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.isDark
                                    ? Colors.white54
                                    : const Color.fromARGB(255, 71, 71, 71),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _DebossedNeumorphicStrip(
                isDark: widget.isDark,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalAvailableWidth = constraints.maxWidth;

                    final double firstStopNaturalWidth =
                        _measureTextWidth(firstStop, stopTextStyle) + 4.0;
                    final double lastStopNaturalWidth =
                        _measureTextWidth(lastStop, stopTextStyle) + 4.0;

                    const double minBeamWidth = 32.0;
                    const double fixedDotSpacing = 36.0;
                    final double maxAllowedForBothStops =
                        (totalAvailableWidth - minBeamWidth - fixedDotSpacing)
                            .clamp(50.0, totalAvailableWidth);

                    final double maxPerSide = maxAllowedForBothStops / 2;

                    final double dynamicFirstWidth = math.min(
                      firstStopNaturalWidth,
                      maxPerSide,
                    );
                    final double dynamicLastWidth = math.min(
                      lastStopNaturalWidth,
                      maxPerSide,
                    );

                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00D2FF),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D2FF)
                                    .withValues(alpha: 0.85),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        SizedBox(
                          width: dynamicFirstWidth,
                          child: AutoScrollStopText(
                            text: firstStop,
                            textAlign: TextAlign.left,
                            style: stopTextStyle,
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: AnimatedBuilder(
                              animation: _connectorPulseController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _AnimatedRouteBeamPainter(
                                    progress: _connectorPulseController.value,
                                    isDark: widget.isDark,
                                  ),
                                  child: const SizedBox(height: 14),
                                );
                              },
                            ),
                          ),
                        ),

                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.white54
                                  : Colors.black45,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        SizedBox(
                          width: dynamicLastWidth,
                          child: AutoScrollStopText(
                            text: lastStop,
                            textAlign: TextAlign.right,
                            style: stopTextStyle,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg(widget.isDark),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppTheme.neumorphicShadows(widget.isDark,
                            depth: 4, blur: 7),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardBg(widget.isDark),
                          foregroundColor:
                              AppTheme.textPrimary(widget.isDark),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: widget.onStopsTap,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: widget.isDark
                                  ? AppTheme.accentCyan
                                  : AppTheme.darkNavy,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Stops',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary(widget.isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.darkNavy, AppTheme.cyanBlue],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.darkNavy.withValues(
                                alpha: widget.isDark ? 0.70 : 0.40),
                            offset: const Offset(-2, 4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: AppTheme.cyanBlue.withValues(
                                alpha: widget.isDark ? 0.45 : 0.25),
                            offset: const Offset(3, 4),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: _handleTrackTap,
                          child: AnimatedBuilder(
                            animation: _arrowLaunchController,
                            builder: (context, child) {
                              final double textOpacity = (1.0 -
                                      (_arrowLaunchController.value * 1.8))
                                  .clamp(0.0, 1.0);
                              final double arrowOpacity = (1.0 -
                                      (_arrowLaunchController.value * 1.2))
                                  .clamp(0.0, 1.0);

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: arrowOpacity,
                                    child: Transform.translate(
                                      offset: Offset(_arrowLaunchAnim.value, 0),
                                      child: const _SolidChevronArrow(
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Opacity(
                                    opacity: textOpacity,
                                    child: const Text(
                                      'Track',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebossedNeumorphicStrip extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _DebossedNeumorphicStrip({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DebossedInnerShadowPainter(isDark: isDark),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: child,
      ),
    );
  }
}

class _DebossedInnerShadowPainter extends CustomPainter {
  final bool isDark;

  _DebossedInnerShadowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect =
        RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final Paint cavityBasePaint = Paint()
      ..color = isDark ? const Color(0xFF061423) : const Color(0xFFDFE7F0);
    canvas.drawRRect(rrect, cavityBasePaint);

    canvas.save();
    canvas.clipRRect(rrect);

    final Path outerBounds = Path()..addRect(rect.inflate(30));

    final Paint darkShadowPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.92)
          : const Color(0xFF7A8B9C).withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final Path shiftedDark = Path()
      ..addRRect(rrect.shift(const Offset(3.5, 4.0)));
    final Path darkShadowPath =
        Path.combine(PathOperation.difference, outerBounds, shiftedDark);
    canvas.drawPath(darkShadowPath, darkShadowPaint);

    final Paint creasePaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.98)
          : const Color(0xFF5A6C7E).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

    final Path shiftedCrease = Path()
      ..addRRect(rrect.shift(const Offset(1.5, 2.0)));
    final Path creasePath =
        Path.combine(PathOperation.difference, outerBounds, shiftedCrease);
    canvas.drawPath(creasePath, creasePaint);

    final Paint lightHighlightPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1B456F).withValues(alpha: 0.40)
          : Colors.white.withValues(alpha: 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final Path shiftedLight = Path()
      ..addRRect(rrect.shift(const Offset(-3.0, -3.0)));
    final Path lightHighlightPath =
        Path.combine(PathOperation.difference, outerBounds, shiftedLight);
    canvas.drawPath(lightHighlightPath, lightHighlightPaint);

    final Paint rimLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.45)
          : Colors.black.withValues(alpha: 0.06);
    canvas.drawRRect(rrect, rimLinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DebossedInnerShadowPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _AnimatedRouteBeamPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _AnimatedRouteBeamPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;

    final Paint trackPaint = Paint()
      ..color = isDark
          ? const Color(0xFF00D2FF).withValues(alpha: 0.18)
          : const Color(0xFF00658D).withValues(alpha: 0.20)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), trackPaint);

    final double particleX = size.width * progress;

    final Paint tailPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          (isDark ? const Color(0xFF00D2FF) : const Color(0xFF0073A8))
              .withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(
          (particleX - 24).clamp(0.0, size.width), midY - 2, 24, 4))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset((particleX - 22).clamp(0.0, size.width), midY),
      Offset(particleX, midY),
      tailPaint,
    );

    final Paint particleGlow = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final Paint particleCore = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF00A3E0)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(particleX, midY), 3.5, particleGlow);
    canvas.drawCircle(Offset(particleX, midY), 2.2, particleCore);
  }

  @override
  bool shouldRepaint(covariant _AnimatedRouteBeamPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

class _SolidChevronArrow extends StatelessWidget {
  final double size;
  final Color color;

  const _SolidChevronArrow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SolidChevronPainter(color: color),
      ),
    );
  }
}

class _SolidChevronPainter extends CustomPainter {
  final Color color;
  _SolidChevronPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    final Path path = Path()
      ..moveTo(0, h * 0.08)
      ..lineTo(w * 0.95, h * 0.50)
      ..lineTo(0, h * 0.92)
      ..lineTo(w * 0.35, h * 0.50)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderRouteSignalPainter extends CustomPainter {
  final bool isDark;

  const _HeaderRouteSignalPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final Rect rect = Rect.fromLTWH(0, 0, w, h);

    final Offset radarCenter = Offset(w * 0.88, h * 0.28);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.76, -0.45),
        radius: 1.0,
        colors: [
          (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0073A8))
              .withValues(alpha: isDark ? 0.16 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    for (int i = 1; i <= 3; i++) {
      final double r = i * 32.0;
      final double ringAlpha = (0.09 - (i * 0.025)).clamp(0.02, 0.09);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = (isDark ? const Color(0xFF00E5FF) : Colors.white)
            .withValues(alpha: isDark ? ringAlpha : ringAlpha * 0.7);
      canvas.drawCircle(radarCenter, r, ringPaint);
    }

    final mainPath = Path()
      ..moveTo(-15, h * 0.30)
      ..cubicTo(w * 0.32, h * 0.12, w * 0.52, h * 0.72, w * 1.05, h * 0.50);

    final glowLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? const Color(0xFF00E5FF) : const Color(0xFF00A3E0))
          .withValues(alpha: isDark ? 0.22 : 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(mainPath, glowLinePaint);

    final mainLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          (isDark ? const Color(0xFF00E5FF) : Colors.white)
              .withValues(alpha: 0.08),
          (isDark ? const Color(0xFF00F0FF) : const Color(0xFF00D2FF))
              .withValues(alpha: isDark ? 0.75 : 0.45),
          (isDark ? const Color(0xFF0088FF) : const Color(0xFF00537A))
              .withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawPath(mainPath, mainLinePaint);

    final dashedPath = Path()
      ..moveTo(w * 0.18, -10)
      ..cubicTo(w * 0.26, h * 0.48, w * 0.68, h * 0.32, w * 0.84, h * 1.15);

    final dashedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = (isDark ? const Color(0xFF38BDF8) : Colors.white)
          .withValues(alpha: isDark ? 0.28 : 0.14);
    _drawDashedPath(canvas, dashedPath, dashedPaint, 6.0, 6.0);

    _drawWaypoint(canvas, Offset(w * 0.42, h * 0.40), isHero: true);
    _drawWaypoint(canvas, Offset(w * 0.74, h * 0.56), isHero: false);
    _drawWaypoint(canvas, Offset(w * 0.12, h * 0.25), isHero: false);
  }

  void _drawWaypoint(Canvas canvas, Offset pos, {required bool isHero}) {
    final double r = isHero ? 4.0 : 2.5;

    canvas.drawCircle(
      pos,
      r * 2.6,
      Paint()
        ..color =
            const Color(0xFF00E5FF).withValues(alpha: isHero ? 0.35 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = isDark ? const Color(0xFF00F0FF) : Colors.white,
    );

    canvas.drawCircle(
      pos,
      r * 0.45,
      Paint()
        ..style = PaintingStyle.fill
        ..color = isDark ? Colors.white : const Color(0xFF00D2FF),
    );
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in path.computeMetrics()) {
      double dist = 0.0;
      while (dist < metric.length) {
        final double len = (dist + dashWidth < metric.length)
            ? dashWidth
            : metric.length - dist;
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderRouteSignalPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

PageRouteBuilder smoothPageRoute({required Widget page}) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

class NeonSearchBarContainer extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final bool isFocused;

  const NeonSearchBarContainer({
    super.key,
    required this.child,
    required this.isDark,
    this.isFocused = false,
  });

  @override
  State<NeonSearchBarContainer> createState() => _NeonSearchBarContainerState();
}

class _NeonSearchBarContainerState extends State<NeonSearchBarContainer>
    with SingleTickerProviderStateMixin {
  Offset? _touchPosition;
  late final AnimationController _glowController;
  late final Animation<double> _glowIntensity;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _glowIntensity = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOutCubic,
    );

    if (widget.isFocused) {
      _glowController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant NeonSearchBarContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _glowController.forward();
      } else if (_touchPosition == null) {
        _glowController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _activateGlow(Offset localPos) {
    setState(() => _touchPosition = localPos);
    _glowController.stop();
    _glowController.value = 1.0;
  }

  void _releaseGlow() {
    if (!widget.isFocused) {
      _glowController.reverse(from: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color barBg = widget.isDark ? const Color(0xFF071B30) : Colors.white;

    return MouseRegion(
      onEnter: (e) => _activateGlow(e.localPosition),
      onHover: (e) => setState(() => _touchPosition = e.localPosition),
      onExit: (_) => _releaseGlow(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) => _activateGlow(d.localPosition),
        onPanUpdate: (d) => setState(() => _touchPosition = d.localPosition),
        onPanEnd: (_) => _releaseGlow(),
        onPanCancel: () => _releaseGlow(),
        child: AnimatedBuilder(
          animation: _glowIntensity,
          builder: (context, _) {
            final double intensity = _glowIntensity.value;

            return Container(
              decoration: BoxDecoration(
                color: barBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: widget.isDark ? 0.35 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (intensity > 0.01)
                    BoxShadow(
                      color: (widget.isDark
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF0284C7))
                          .withValues(
                        alpha: (widget.isDark ? 0.32 : 0.28) * intensity,
                      ),
                      blurRadius: 16 * intensity,
                      spreadRadius: 1.2 * intensity,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _NeonSearchBarPainter(
                          touchPosition: _touchPosition,
                          intensity: intensity,
                          isDark: widget.isDark,
                        ),
                      ),
                    ),
                    widget.child,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NeonSearchBarPainter extends CustomPainter {
  final Offset? touchPosition;
  final double intensity;
  final bool isDark;

  const _NeonSearchBarPainter({
    required this.touchPosition,
    required this.intensity,
    required this.isDark,
  });

  static const List<Color> _darkPalette = [
    Color(0xFFFFFFFF),
    Color(0xFF00F0FF),
    Color(0xFF0088FF),
    Colors.transparent,
  ];

  static const List<Color> _lightPalette = [
    Color(0xFF00F0FF),
    Color(0xFF0284C7),
    Color(0xFF0F172A),
    Colors.transparent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    final baseBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.10)
          : const Color(0xFF0F172A).withValues(alpha: 0.12);

    canvas.drawRRect(rrect, baseBorderPaint);

    if (intensity > 0.01) {
      final pos = touchPosition ?? Offset(size.width * 0.5, size.height * 0.5);
      final Alignment centerAlignment = Alignment(
        (pos.dx / size.width) * 2 - 1,
        (pos.dy / size.height) * 2 - 1,
      );

      if (!isDark) {
        final darkAuraShader = RadialGradient(
          center: centerAlignment,
          radius: 1.1,
          colors: [
            const Color(0xFF0077B6).withValues(alpha: 0.22 * intensity),
            const Color(0xFF0F172A).withValues(alpha: 0.12 * intensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);

        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0 * intensity
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
            ..shader = darkAuraShader,
        );
      }

      final borderShader = RadialGradient(
        center: centerAlignment,
        radius: 1.3,
        colors: isDark ? _darkPalette : _lightPalette,
        stops: const [0.0, 0.25, 0.65, 1.0],
      ).createShader(rect);

      final neonPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isDark ? 2.2 : 2.4) * intensity
        ..shader = borderShader;

      canvas.drawRRect(rrect, neonPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonSearchBarPainter oldDelegate) =>
      oldDelegate.touchPosition != touchPosition ||
      oldDelegate.intensity != intensity ||
      oldDelegate.isDark != isDark;
}