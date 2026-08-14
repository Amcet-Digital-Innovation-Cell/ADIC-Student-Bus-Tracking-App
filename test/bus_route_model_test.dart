import 'package:flutter_test/flutter_test.dart';
import 'package:fluttermobileapp/models/bus_model.dart';

void main() {
  group('BusRouteModel', () {
    test('getStops(false) keeps the forward stops in original order', () {
      final route = BusRouteModel(
        id: '1',
        routeName: 'Sankaranpalayam',
        busNo: 'Bus 10',
        forwardStops: ['Main Bus St', 'Sankaranpalayam', 'Old Bus Stand'],
      );

      expect(route.getStops(false), ['Main Bus St', 'Sankaranpalayam', 'Old Bus Stand']);
    });

    test('getStops(true) reverses the stop list for the evening return trip', () {
      final route = BusRouteModel(
        id: '1',
        routeName: 'Sankaranpalayam',
        busNo: 'Bus 10',
        forwardStops: ['Main Bus St', 'Sankaranpalayam', 'Old Bus Stand'],
      );

      expect(route.getStops(true), ['Old Bus Stand', 'Sankaranpalayam', 'Main Bus St']);
    });
  });
}
