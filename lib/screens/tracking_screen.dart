import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/bus_model.dart';
import '../models/vehicle_tracking_model.dart';
import '../services/api_service.dart';
import 'stops_bottom_sheet.dart';
import 'bus_icon_widget.dart';
import 'theme_controller.dart';

class TrackingScreen extends StatefulWidget {
  final BusRouteModel bus;
  final bool? isEveningReturn;
  final DateTime Function()? timeProvider;

  const TrackingScreen({
    super.key,
    required this.bus,
    this.isEveningReturn,
    this.timeProvider,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _initialLocation = LatLng(12.9165, 79.1325);

  late final AnimationController _radarController;
  late final AnimationController _waveSignalController;
  late final bool _computedEveningMode;

  LatLng? _markerLocation = _initialLocation;
  double _headingDegrees = 0.0;
  VehicleTrackingModel? _tracking;
  io.Socket? _socket;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _computedEveningMode = widget.isEveningReturn ?? _isEveningTime();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _waveSignalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _fetchTracking();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _waveSignalController.dispose();
    _socket?.disconnect();
    _socket?.destroy();
    super.dispose();
  }

  bool _isEveningTime() {
    final now = widget.timeProvider?.call() ?? DateTime.now();
    return now.hour >= 12;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double startLat = start.latitude * (math.pi / 180.0);
    final double startLng = start.longitude * (math.pi / 180.0);
    final double endLat = end.latitude * (math.pi / 180.0);
    final double endLng = end.longitude * (math.pi / 180.0);

    final double dLng = endLng - startLng;
    final double y = math.sin(dLng) * math.cos(endLat);
    final double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    return (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
  }

  double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '0') ?? 0.0;
  }

  void _initSocket(String vehicleId) {
    _socket?.disconnect();
    _socket?.destroy();

    _socket = io.io(
      ApiService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket!.onConnect((_) => _socket!.emit('joinVehicle', vehicleId));

    _socket!.onDisconnect((_) {
      if (mounted) {
        setState(() => _errorMessage = 'Connection lost. Reconnecting…');
      }
    });

    _socket!.on('busLocationUpdated', (data) {
      if (!mounted || data == null) return;
      if (data['vehicleNumber']?.toString().toUpperCase() !=
          vehicleId.toUpperCase()) {
        return;
      }

      final double lat = _toDouble(data['latitude']);
      final double lng = _toDouble(data['longitude']);
      final LatLng newLocation = LatLng(lat, lng);
      final bool ignitionOn = VehicleTrackingModel.fromJson({
        'vehicleId': vehicleId,
        'latitude': lat,
        'longitude': lng,
        'updatedAt': data['receivedAt']?.toString() ??
            data['gpsActualTime']?.toString() ??
            DateTime.now().toUtc().toIso8601String(),
        'ignitionOn':
            data['ignitionOn'] ?? data['ignition'] ?? data['isIgnitionOn'],
        'rawStatus': data['rawStatus'] ?? data['status'],
      }).isIgnitionOn;

      final dynamic rawBearing =
          data['bearing'] ?? data['heading'] ?? data['course'];
      if (rawBearing != null) {
        _headingDegrees = _toDouble(rawBearing) % 360.0;
      } else if (_markerLocation != null &&
          (_markerLocation!.latitude != lat ||
              _markerLocation!.longitude != lng)) {
        _headingDegrees = _calculateBearing(_markerLocation!, newLocation);
      }

      setState(() {
        _tracking = VehicleTrackingModel(
          routeId: widget.bus.id,
          vehicleId: vehicleId,
          latitude: lat,
          longitude: lng,
          updatedAt: DateTime.tryParse(
                data['receivedAt']?.toString() ??
                    data['gpsActualTime']?.toString() ??
                    '',
              ) ??
              DateTime.now(),
          speedKph: data['speed'] is int
              ? data['speed'] as int
              : int.tryParse(data['speed']?.toString() ?? ''),
          status: data['rawStatus']?.toString() ?? data['status']?.toString(),
          isIgnitionOn: ignitionOn,
        );
        _markerLocation = newLocation;
        _errorMessage =
            ignitionOn ? null : 'Ignition off – live tracking paused';
      });
      _animatedMapMove(newLocation, 17.2);
    });
  }

  Future<void> _fetchTracking() async {
    setState(() => _errorMessage = null);

    try {
      final tracking = await ApiService.fetchVehicleTracking(
        routeId: widget.bus.id,
        mode: _computedEveningMode ? 'evening' : 'morning',
      );

      if (!mounted) return;

      if (tracking != null) {
        final LatLng newLoc = LatLng(tracking.latitude, tracking.longitude);
        if (_markerLocation != null &&
            (_markerLocation!.latitude != tracking.latitude ||
                _markerLocation!.longitude != tracking.longitude)) {
          _headingDegrees = _calculateBearing(_markerLocation!, newLoc);
        }

        setState(() {
          _tracking = tracking;
          _markerLocation = newLoc;
          _errorMessage = tracking.isTrackingActive
              ? null
              : 'Ignition off – live tracking paused';
        });
        _animatedMapMove(newLoc, 17.2);

        if (tracking.vehicleId.isNotEmpty && tracking.isTrackingActive) {
          _initSocket(tracking.vehicleId);
        } else {
          _socket?.disconnect();
          _socket?.destroy();
          _socket = null;
        }
      } else {
        setState(() {
          _errorMessage = _markerLocation != null
              ? 'Live feed unavailable – showing last known location'
              : 'Live bus location is unavailable right now.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _markerLocation != null
            ? 'Unable to fetch live data – showing last known location.'
            : 'Unable to fetch live data.';
      });
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    controller.addListener(() {
      final double lat = latTween.evaluate(animation);
      final double lng = lngTween.evaluate(animation);
      final double zoom = zoomTween.evaluate(animation);

      _mapController.move(LatLng(lat, lng), zoom);
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _showStopsModal(
      BuildContext context, BusRouteModel bus, bool isEvening) {
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

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 24,
      height: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFF1F5F9),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkMode,
      builder: (context, isDark, _) {
        final Color cardBg = isDark ? const Color(0xFF091C30) : Colors.white;
        final Color textTitle = isDark ? Colors.white : const Color(0xFF0F172A);
        final Color textSub =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return Scaffold(
          backgroundColor: AppTheme.bgSurface(isDark),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _initialLocation,
                  initialZoom: 17.2,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.pinchZoom |
                        InteractiveFlag.scrollWheelZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.pinchMove,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.amcet.bustracking',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _markerLocation ?? _initialLocation,
                        width: 66,
                        height: 66,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: _headingDegrees),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, angle, child) {
                            return _buildRadarAnimatedMarker(isDark);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Top Status Bar with Signal Wave Background
              Positioned(
                top: 33,
                left: 13,
                right: 13,
                child: Row(
                  children: [
                    _buildFloatingRoundButton(
                      icon: Icons.arrow_back_rounded,
                      cardBg: cardBg,
                      iconColor: textTitle,
                      isDark: isDark,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFCBD5E1)
                                    .withValues(alpha: 0.85),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.40)
                                  : const Color(0xFF0F172A)
                                      .withValues(alpha: 0.07),
                              offset: const Offset(0, 4),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: isDark
                                        ? const RadialGradient(
                                            center: Alignment(-0.7, -0.8),
                                            radius: 1.4,
                                            colors: [
                                              Color(0xFF13304F),
                                              Color(0xFF0B2038),
                                              Color(0xFF061526),
                                            ],
                                            stops: [0.0, 0.55, 1.0],
                                          )
                                        : const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFFFFFFF),
                                              Color(0xFFF8FAFC)
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              // Signal telemetry waves
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _waveSignalController,
                                  builder: (context, _) => CustomPaint(
                                    painter: _SignalWaveLinesPainter(
                                      progress: _waveSignalController.value,
                                      isDark: isDark,
                                      amplitudeMultiplier: 0.65,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _errorMessage == null
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_errorMessage == null
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFF59E0B))
                                                .withValues(alpha: 0.65),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _computedEveningMode
                                                ? 'EVENING (TO HOME)'
                                                : 'MORNING (TO COLLEGE)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: textTitle,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _errorMessage ??
                                                (_tracking?.isTrackingActive ??
                                                        false
                                                    ? 'Live GPS tracking active'
                                                    : 'Ignition off – live tracking paused'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSub,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildFloatingRoundButton(
                      icon: isDark
                          ? Icons.wb_sunny_rounded
                          : Icons.nightlight_round,
                      cardBg: cardBg,
                      iconColor: isDark
                          ? const Color(0xFF00D2FF)
                          : const Color(0xFF0F172A),
                      isDark: isDark,
                      onTap: AppTheme.toggleTheme,
                    ),
                  ],
                ),
              ),

              // Right-Side Corner 4-Button Pillar
              Positioned(
                right: 18,
                bottom: 128,
                child: _InteractiveNeonGlowCard(
                  borderRadius: 24,
                  isDark: isDark,
                  cardBg: cardBg,
                  child: Column(
                    children: [
                      _buildPillarAction(
                        icon: Icons.add_rounded,
                        color: textTitle,
                        onTap: () {
                          final cam = _mapController.camera;
                          _animatedMapMove(
                              cam.center, (cam.zoom + 1).clamp(3.0, 19.0));
                        },
                      ),
                      _buildDivider(isDark),
                      _buildPillarAction(
                        icon: Icons.remove_rounded,
                        color: textTitle,
                        onTap: () {
                          final cam = _mapController.camera;
                          _animatedMapMove(
                              cam.center, (cam.zoom - 1).clamp(3.0, 19.0));
                        },
                      ),
                      _buildDivider(isDark),
                      _buildPillarAction(
                        icon: Icons.my_location_rounded,
                        color: const Color(0xFF00E5FF),
                        onTap: () => _animatedMapMove(
                            _markerLocation ?? _initialLocation, 17.2),
                      ),
                      _buildDivider(isDark),
                      _buildPillarAction(
                        icon: Icons.refresh_rounded,
                        color: textTitle,
                        onTap: _fetchTracking,
                      ),
                    ],
                  ),
                ),
              ),

              // Map Scale Bar
              Positioned(
                left: 25,
                bottom: 128,
                child: StreamBuilder<MapEvent>(
                  stream: _mapController.mapEventStream,
                  builder: (context, snapshot) {
                    return MapScaleBar(
                      camera: _mapController.camera,
                      isDark: isDark,
                    );
                  },
                ),
              ),

              // Bottom Details Card with Signal Wave Background
              Positioned(
                bottom: 22,
                left: 18,
                right: 18,
                child: _InteractiveNeonGlowCard(
                  borderRadius: 26,
                  isDark: isDark,
                  cardBg: cardBg,
                  onTap: () => _showStopsModal(
                      context, widget.bus, _computedEveningMode),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _waveSignalController,
                          builder: (context, _) => CustomPaint(
                            painter: _SignalWaveLinesPainter(
                              progress: _waveSignalController.value,
                              isDark: isDark,
                              amplitudeMultiplier: 1.0,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            NeumorphicBusIcon(size: 46, isDark: isDark),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF003354)
                                              : const Color(0xFFE0F2FE),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          widget.bus.busNo,
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFF38BDF8)
                                                : const Color(0xFF0369A1),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• Tap to view stops',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSub,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.bus.routeName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textTitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: textTitle,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillarAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildFloatingRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color cardBg,
    required Color iconColor,
    required bool isDark,
  }) {
    return _InteractiveNeonGlowCard(
      borderRadius: 22,
      isDark: isDark,
      cardBg: cardBg,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildRadarAnimatedMarker(bool isDark) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        final double pulse = _radarController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 42 + (pulse * 24),
              height: 42 + (pulse * 24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (isDark ? const Color(0xFF00D2FF) : const Color(0xFF0284C7))
                        .withValues(alpha: (1.0 - pulse) * 0.35),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF00D2FF), Color(0xFF001E40)]
                : const [Color(0xFF0284C7), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Hero(
            tag: 'nav_arrow_${widget.bus.id}',
            child: AnimatedRotation(
              turns: _headingDegrees / 360.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for background sinusoidal telemetry signal waves and tracking nodes
class _SignalWaveLinesPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final double amplitudeMultiplier;

  const _SignalWaveLinesPainter({
    required this.progress,
    required this.isDark,
    this.amplitudeMultiplier = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final double phase = progress * 2 * math.pi;

    final Color primaryCyan =
        isDark ? const Color(0xFF00D2FF) : const Color(0xFF0284C7);
    final Color secondaryCobalt =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);

    // Primary High Frequency Signal Wave
    final ui.Path wavePath1 = ui.Path();
    final double amp1 = 8.0 * amplitudeMultiplier;
    final double midY1 = h * 0.52;

    for (double x = 0; x <= w; x += 3.0) {
      final double y = midY1 + math.sin((x / w * 3.5 * math.pi) - phase) * amp1;
      if (x == 0) {
        wavePath1.moveTo(x, y);
      } else {
        wavePath1.lineTo(x, y);
      }
    }

    final Paint wavePaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = primaryCyan.withValues(alpha: isDark ? 0.18 : 0.12);

    canvas.drawPath(wavePath1, wavePaint1);

    // Secondary Gentle Carrier Wave
    final ui.Path wavePath2 = ui.Path();
    final double amp2 = 5.0 * amplitudeMultiplier;
    final double midY2 = h * 0.62;

    for (double x = 0; x <= w; x += 4.0) {
      final double y =
          midY2 + math.cos((x / w * 2.2 * math.pi) + (phase * 0.7)) * amp2;
      if (x == 0) {
        wavePath2.moveTo(x, y);
      } else {
        wavePath2.lineTo(x, y);
      }
    }

    final Paint wavePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = secondaryCobalt.withValues(alpha: isDark ? 0.14 : 0.08);

    canvas.drawPath(wavePath2, wavePaint2);

    // Dynamic Waypoint Signal Nodes along the primary wave
    final List<double> nodeFractions = [0.25, 0.55, 0.85];
    for (final fraction in nodeFractions) {
      final double nodeX = (w * ((fraction + (progress * 0.25)) % 1.0));
      final double nodeY =
          midY1 + math.sin((nodeX / w * 3.5 * math.pi) - phase) * amp1;

      canvas.drawCircle(
        Offset(nodeX, nodeY),
        3.0,
        Paint()..color = primaryCyan.withValues(alpha: isDark ? 0.35 : 0.20),
      );
      canvas.drawCircle(
        Offset(nodeX, nodeY),
        1.5,
        Paint()..color = isDark ? Colors.white : primaryCyan,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalWaveLinesPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDark != isDark ||
      oldDelegate.amplitudeMultiplier != amplitudeMultiplier;
}

class _InteractiveNeonGlowCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool isDark;
  final Color cardBg;
  final VoidCallback? onTap;

  const _InteractiveNeonGlowCard({
    required this.child,
    required this.borderRadius,
    required this.isDark,
    required this.cardBg,
    this.onTap,
  });

  @override
  State<_InteractiveNeonGlowCard> createState() =>
      _InteractiveNeonGlowCardState();
}

class _InteractiveNeonGlowCardState extends State<_InteractiveNeonGlowCard>
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
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
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
              decoration: BoxDecoration(
                color: widget.cardBg,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark
                        ? Colors.black.withValues(alpha: 0.40)
                        : const Color(0xFF0F172A).withValues(alpha: 0.07),
                    offset: const Offset(0, 6),
                    blurRadius: 16,
                  ),
                  if (intensity > 0.01)
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(
                        alpha: (widget.isDark ? 0.35 : 0.20) * intensity,
                      ),
                      blurRadius: 14 + (6 * intensity),
                      spreadRadius: 1.0 * intensity,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  children: [
                    // Ambient card cavity gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: widget.isDark
                              ? const RadialGradient(
                                  center: Alignment(-0.7, -0.8),
                                  radius: 1.4,
                                  colors: [
                                    Color(0xFF13304F),
                                    Color(0xFF0B2038),
                                    Color(0xFF061526),
                                  ],
                                  stops: [0.0, 0.55, 1.0],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF8FAFC)
                                  ],
                                ),
                        ),
                      ),
                    ),
                    // Reactive Touch Neon Border
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _NeonBorderGlowPainter(
                          touchPosition: _touchPosition,
                          intensity: intensity,
                          borderRadius: widget.borderRadius,
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

class _NeonBorderGlowPainter extends CustomPainter {
  final Offset? touchPosition;
  final double intensity;
  final double borderRadius;
  final bool isDark;

  const _NeonBorderGlowPainter({
    required this.touchPosition,
    required this.intensity,
    required this.borderRadius,
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
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Base subtle border outline
    final baseBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFCBD5E1).withValues(alpha: 0.85);

    canvas.drawRRect(rrect, baseBorderPaint);

    if (intensity > 0.01 && touchPosition != null) {
      final pos = touchPosition!;
      final Alignment centerAlignment = Alignment(
        (pos.dx / size.width) * 2 - 1,
        (pos.dy / size.height) * 2 - 1,
      );

      // Radial interior wash around touch point
      final auraShader = RadialGradient(
        center: centerAlignment,
        radius: 0.75,
        colors: [
          (isDark ? const Color(0xFF00F0FF) : const Color(0xFF0284C7))
              .withValues(alpha: (isDark ? 0.22 : 0.14) * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);

      canvas.drawRRect(rrect, Paint()..shader = auraShader);

      // Dynamic electric neon border stroke
      final borderShader = RadialGradient(
        center: centerAlignment,
        radius: 1.2,
        colors: isDark ? _darkPalette : _lightPalette,
        stops: const [0.0, 0.25, 0.65, 1.0],
      ).createShader(rect);

      final neonBorderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isDark ? 2.6 : 2.2) * intensity
        ..shader = borderShader;

      canvas.drawRRect(rrect, neonBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonBorderGlowPainter oldDelegate) {
    return oldDelegate.touchPosition != touchPosition ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isDark != isDark;
  }
}

class MapScaleBar extends StatelessWidget {
  final MapCamera camera;
  final bool isDark;

  const MapScaleBar({
    super.key,
    required this.camera,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double latitude = camera.center.latitude;
    final double zoom = camera.zoom;
    final double metersPerPixel =
        (156543.03392 * math.cos(latitude * math.pi / 180.0)) /
            math.pow(2.0, zoom);

    const double maxBarWidth = 80.0;
    final double maxMeters = maxBarWidth * metersPerPixel;

    final double displayDistance = _calculateNiceDistance(maxMeters);
    final double actualBarWidth = displayDistance / metersPerPixel;

    final String label = displayDistance >= 1000
        ? '${(displayDistance / 1000).toStringAsFixed(displayDistance % 1000 == 0 ? 0 : 1)} km'
        : '${displayDistance.toInt()} m';

    final Color primaryColor =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF00567A);
    final Color barColor =
        isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF041224) : Colors.white)
            .withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? const ui.Color.fromARGB(51, 255, 255, 255)
                  .withValues(alpha: 0.10)
              : const ui.Color.fromARGB(31, 0, 0, 0).withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: primaryColor,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: actualBarWidth.clamp(20.0, 100.0),
            height: 10,
            child: CustomPaint(
              painter: _ScaleBarPainter(color: barColor),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateNiceDistance(double maxMeters) {
    const List<double> steps = [
      10,
      20,
      50,
      100,
      200,
      500,
      1000,
      2000,
      5000,
      10000,
      20000,
      50000,
      100000
    ];
    for (int i = steps.length - 1; i >= 0; i--) {
      if (maxMeters >= steps[i]) {
        return steps[i];
      }
    }
    return 10.0;
  }
}

class _ScaleBarPainter extends CustomPainter {
  final Color color;

  const _ScaleBarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final ui.Path path = ui.Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(0.0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0.0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScaleBarPainter oldDelegate) =>
      oldDelegate.color != color;
}
