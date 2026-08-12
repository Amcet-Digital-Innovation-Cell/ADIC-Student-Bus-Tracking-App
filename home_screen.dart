import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import 'tracking_screen.dart';
import 'stops_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final DateTime Function()? timeProvider;

  const HomeScreen({super.key, this.timeProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller for the search text field
  final TextEditingController _searchController = TextEditingController();
  
  // State variable to hold the filtered routes
  List<BusRouteModel> _filteredRoutes = [];

  // Automated time check: returns true if 12:00 PM or later (Evening Return)
  bool get _isEveningTime {
    final now = widget.timeProvider?.call() ?? DateTime.now();
    return now.hour >= 12;
  }

  final List<BusRouteModel> routes = [
    BusRouteModel(
      id: '1',
      routeName: 'Sankaranpalayam',
      busNo: 'Bus 10',
      forwardStops: ['Main Bus St', 'Sankaranpalayam', 'Old Bus Stand', 'Collectorate', 'AMCET'],
    ),
    BusRouteModel(
      id: '2',
      routeName: 'kannamangalam',
      busNo: 'Bus 05',
      forwardStops: ['kannamangalam', 'kanyambadi', 'adukamparai', 'old bus','AMCET'],
    ),
    BusRouteModel(
      id: '3',
      routeName: 'Vellore',
      busNo: 'Bus 10',
      forwardStops: ['Main Bus St', 'Vellore', 'Collectorate', 'AMCET'],
    ),
    BusRouteModel(
      id: '4',
      routeName: 'Walaja',
      busNo: 'Bus 14',
      forwardStops: ['Walaja Toll', 'Ranipet', 'Arcot', 'Collectorate', 'AMCET'],
    ),
    BusRouteModel(
      id: '5',
      routeName: 'Sholingur',
      busNo: 'Bus 18',
      forwardStops: ['Sholigur','navalpur','Ranipet collectrate','sipcot','tiruvalam','puttuthakku','old','new','loke','oval','turf','AMCET'],
    )
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the filtered routes with all routes initially
    _filteredRoutes = routes;
    // Listen to changes in the search field
    _searchController.addListener(_filterRoutes);
  }

  void _filterRoutes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRoutes = routes.where((bus) {
        final matchesBusName = bus.routeName.toLowerCase().contains(query);
        final matchesBusNo = bus.busNo.toLowerCase().contains(query);
        final matchesStop = bus.forwardStops.any((stop) => stop.toLowerCase().contains(query));
        
        return matchesBusName || matchesBusNo || matchesStop;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStopsModal(BuildContext context, BusRouteModel bus, bool isEvening) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StopsBottomSheet(
        bus: bus,
        isEveningReturn: isEvening,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEvening = _isEveningTime;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Container
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF5E43F3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Where to go?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Track your bus in real-time.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Input Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController, // Connected controller
                      decoration: InputDecoration(
                        hintText: 'Search bus or stop name...',
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section Title & Bus Count Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Available Routes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E2F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredRoutes.length} buses',
                        style: const TextStyle(
                          color: Color(0xFF5E43F3),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Route Cards ListView
            Expanded(
              child: _filteredRoutes.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching buses or stops found',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final bus = _filteredRoutes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE4E2F8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.directions_bus, color: Color(0xFF5E43F3), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bus.routeName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2D3142),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF5E43F3),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                bus.busNo,
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${bus.forwardStops.length} stops',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Origin ------------ Destination preview row
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.circle, size: 8, color: Color(0xFF5E43F3)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            bus.forwardStops.first,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      transform: Matrix4.translationValues(0, -3.5, 0),
                                      child: const Text(
                                        '..................',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey, fontSize: 15,height:1.2),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.radio_button_unchecked, size: 10, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            bus.forwardStops.last,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Action Buttons: Stops (Left) & Track (Right)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            side: const BorderSide(color: Color(0xFF5E43F3)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          icon: const Icon(Icons.list, color: Color(0xFF5E43F3), size: 18),
                                          label: const FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text('Stops', style: TextStyle(color: Color(0xFF5E43F3), fontWeight: FontWeight.bold)),
                                          ),
                                          onPressed: () => _showStopsModal(context, bus, isEvening),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF5E43F3),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            elevation: 2,
                                          ),
                                          icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                                          label: const FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text('Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TrackingScreen(
                                                  bus: bus,
                                                  isEveningReturn: isEvening,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}