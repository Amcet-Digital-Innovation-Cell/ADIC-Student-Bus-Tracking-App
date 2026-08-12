import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';
import 'stops_bottom_sheet.dart';

class TrackingScreen extends StatefulWidget {
  final BusRouteModel bus;
  final bool? isEveningReturn;
  final DateTime Function()? timeProvider;

  const TrackingScreen({super.key, required this.bus, this.isEveningReturn, this.timeProvider});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialLocation = const LatLng(12.9165, 79.1325);
  
  late bool _computedEveningMode;

  @override
  void initState() {
    super.initState();
    // If a mode was passed explicitly, use it; otherwise, calculate based on current time
    _computedEveningMode = widget.isEveningReturn ?? _isEveningTime();
  }

  // Helper method: Returns true if current time is past 12:00 PM (noon)
  bool _isEveningTime() {
    final now = widget.timeProvider?.call() ?? DateTime.now();
    return now.hour >= 12;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Interactive Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.amcet.transport',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _initialLocation,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(Icons.directions_bus, color: Color(0xFF5E43F3), size: 36),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top Header Floating Card (Shows active automated session mode)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF5E43F3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _computedEveningMode ? 'EVENING (RETURN)' : 'MORNING (TO COLLEGE)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.bus.routeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                  onPressed: () => _mapController.move(_initialLocation, 14.0),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Colors.black87),
                  onPressed: () => setState(() {}),
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
                      color: Colors.black.withOpacity(0.15),
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
                      child: const Icon(Icons.directions_bus, color: Color(0xFF5E43F3)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E43F3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.bus.busNo,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '• Tap to view stops',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
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
                    const Icon(Icons.keyboard_arrow_up, color: Color(0xFF5E43F3)),
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