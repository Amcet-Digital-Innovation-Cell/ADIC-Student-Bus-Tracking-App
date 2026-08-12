import 'package:flutter/material.dart';
import '../models/bus_model.dart';

class StopsBottomSheet extends StatelessWidget {
  final BusRouteModel bus;
  final bool isEveningReturn;

  const StopsBottomSheet({super.key, required this.bus, required this.isEveningReturn});

  @override
  Widget build(BuildContext context) {
    final List<String> currentStops = bus.getStops(isEveningReturn);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: Color(0xFF5E43F3)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bus.routeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(isEveningReturn ? 'Evening Route (Return Trip)' : 'Morning Route (To College)', 
                          style: const TextStyle(fontSize: 11, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 32),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.builder(
              itemCount: currentStops.length,
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final stopName = currentStops[index];
                final isStart = index == 0;
                final isFinal = index == currentStops.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isStart || isFinal) ? const Color(0xFF5E43F3) : Colors.white,
                            border: Border.all(color: const Color(0xFF5E43F3), width: 3),
                          ),
                        ),
                        if (!isFinal)
                          Container(width: 2, height: 35, color: const Color(0xFF5E43F3).withOpacity(0.3)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        if (isStart) const Text('STARTING POINT', style: TextStyle(fontSize: 10, color: Color(0xFF5E43F3), fontWeight: FontWeight.bold)),
                        if (isFinal) const Text('DESTINATION', style: TextStyle(fontSize: 10, color: Color(0xFF5E43F3), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}