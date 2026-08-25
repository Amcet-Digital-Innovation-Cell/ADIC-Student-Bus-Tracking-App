import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/bus_model.dart';
import '../models/vehicle_tracking_model.dart';
import '../services/api_service.dart';
import 'stops_bottom_sheet.dart';

class TrackingScreen extends StatefulWidget {
  final BusRouteModel bus;
  final bool? isEveningReturn;
  final DateTime Function()? timeProvider;

  const TrackingScreen(
      {super.key, required this.bus, this.isEveningReturn, this.timeProvider});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialLocation = const LatLng(12.9165, 79.1325);

  late bool _computedEveningMode;
  LatLng? _markerLocation;
  VehicleTrackingModel? _tracking;
  IO.Socket? _socket;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _computedEveningMode = widget.isEveningReturn ?? _isEveningTime();
    _markerLocation = _initialLocation;
    _fetchTracking();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.destroy();
    super.dispose();
  }

  bool _isEveningTime() {
    final now = widget.timeProvider?.call() ?? DateTime.now();
    return now.hour >= 12;
  }

  void _initSocket(String vehicleId) {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.destroy();
    }

    // Connect to the HTTP backend server (port 3001)
    _socket = IO.io(
        ApiService.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build());

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected to Socket.IO Server');
      // Join the vehicle room using the existing backend pattern
      _socket!.emit('joinVehicle', vehicleId);
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[Socket] Disconnected: $reason');
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection lost. Reconnecting…';
        });
      }
    });

    _socket!.on('connect_error', (error) {
      debugPrint('[Socket] Connection error: $error');
    });

    _socket!.on('busLocationUpdated', (data) {
      if (!mounted) return;
      debugPrint('[Socket] busLocationUpdated received: $data');

      // The payload structure:
      // {
      //   vehicleNumber: string,
      //   latitude: number,
      //   longitude: number,
      //   speed: number,
      //   rawStatus: string,
      //   ignition: string,
      //   location: string,
      //   gpsActualTime: string,
      //   receivedAt: string
      // }
      if (data != null &&
          data['vehicleNumber']?.toString().toUpperCase() ==
              vehicleId.toUpperCase()) {
        setState(() {
          final double lat = (data['latitude'] is num
                  ? data['latitude'] as num
                  : double.tryParse(data['latitude']?.toString() ?? '0') ?? 0)
              .toDouble();
          final double lng = (data['longitude'] is num
                  ? data['longitude'] as num
                  : double.tryParse(data['longitude']?.toString() ?? '0') ?? 0)
              .toDouble();

          _tracking = VehicleTrackingModel(
            routeId: widget.bus.id,
            vehicleId: vehicleId,
            latitude: lat,
            longitude: lng,
            updatedAt: DateTime.tryParse(data['receivedAt']?.toString() ??
                    data['gpsActualTime']?.toString() ??
                    '') ??
                DateTime.now(),
            speedKph: data['speed'] is int
                ? data['speed'] as int
                : int.tryParse(data['speed']?.toString() ?? ''),
            status: data['rawStatus']?.toString(),
          );
          _markerLocation = LatLng(lat, lng);
          _errorMessage = null;
          _mapController.move(_markerLocation!, 14.0);
        });
      }
    });
  }

  Future<void> _fetchTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final previousTracking = _tracking;
    final previousMarker = _markerLocation;

    try {
      final tracking = await ApiService.fetchVehicleTracking(
        routeId: widget.bus.id,
        mode: _computedEveningMode ? 'evening' : 'morning',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        if (tracking != null) {
          // Live data available — update marker and tracking
          _tracking = tracking;
          _markerLocation = LatLng(tracking.latitude, tracking.longitude);
          _errorMessage = null;
          _mapController.move(_markerLocation!, 14.0);

          // Initialize Socket.IO connection for live updates using vehicleId (registration number)
          if (tracking.vehicleId.isNotEmpty) {
            _initSocket(tracking.vehicleId);
          }
        } else if (previousTracking != null) {
          // API returned null — fallback to last known tracking
          _tracking = previousTracking;
          _markerLocation =
              LatLng(previousTracking.latitude, previousTracking.longitude);
          _errorMessage = 'Live feed unavailable — showing last known location';
        } else if (previousMarker != null) {
          // Keep the existing on-screen marker
          _errorMessage = 'Live feed unavailable — showing last known location';
        } else {
          // Nothing available — fallback to initial location
          _tracking = null;
          _markerLocation = _initialLocation;
          _errorMessage = 'Live bus location is unavailable right now.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (previousTracking != null) {
          _tracking = previousTracking;
          _markerLocation =
              LatLng(previousTracking.latitude, previousTracking.longitude);
          _errorMessage =
              'Unable to fetch live data — showing last known location.';
        } else if (previousMarker != null) {
          _errorMessage =
              'Unable to fetch live data — showing last known location.';
        } else {
          _markerLocation = _initialLocation;
          _errorMessage = 'Unable to fetch live data.';
        }
      });
    }
  }

  void _showStopsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StopsBottomSheet(
        bus: widget.bus,
        isEveningReturn: _computedEveningMode,
      ),
    );
  }

  String get _trackingStatus {
    if (_isLoading) {
      return 'Loading live location...';
    }
    if (_tracking != null) {
      final status = _tracking!.status?.toUpperCase() ?? 'UNKNOWN';
      final speed = _tracking!.speedKph != null
          ? '${_tracking!.speedKph} km/h'
          : 'speed unavailable';
      return '$status · $speed';
    }
    return _errorMessage ?? 'Live location not available';
  }

  String get _updatedAtLabel {
    if (_tracking == null) return '';
    return 'Updated ${TimeOfDay.fromDateTime(_tracking!.updatedAt.toLocal()).format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialLocation,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.scrollWheelZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.pinchMove,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.amcet.transport',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _markerLocation ?? _initialLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.directions_bus,
                        color: Color(0xFF5E43F3), size: 36),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5E43F3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.bus.routeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _computedEveningMode
                        ? 'EVENING (RETURN)'
                        : 'MORNING (TO COLLEGE)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _trackingStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  if (_tracking != null)
                    Text(
                      _updatedAtLabel,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                ],
              ),
            ),
          ),

          // Map Action Buttons
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              children: [
                // Zoom In
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final cam = _mapController.camera;
                    _mapController.move(
                        cam.center, (cam.zoom + 1).clamp(3.0, 19.0));
                  },
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                // Zoom Out
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final cam = _mapController.camera;
                    _mapController.move(
                        cam.center, (cam.zoom - 1).clamp(3.0, 19.0));
                  },
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                // Re-center on bus
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                  onPressed: () {
                    final target = _markerLocation ?? _initialLocation;
                    _mapController.move(target, 14.0);
                  },
                ),
                const SizedBox(height: 4),
                // Manual refresh
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  backgroundColor: Colors.white,
                  onPressed: _fetchTracking,
                  child: const Icon(Icons.refresh, color: Colors.black87),
                ),
              ],
            ),
          ),

          // Bottom Clickable Bus Card
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: InkWell(
              onTap: () => _showStopsModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E2F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.directions_bus,
                          color: Color(0xFF5E43F3)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E43F3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.bus.busNo,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '• Tap to view stops',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.bus.routeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_up,
                        color: Color(0xFF5E43F3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
