import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttermobileapp/models/vehicle_tracking_model.dart';
import 'package:fluttermobileapp/services/api_service.dart';

void main() {
  group('ApiService.fetchRoutes', () {
    test('parses a valid JSON list into BusRouteModel objects', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': '1',
              'routeName': 'Sankaranpalayam',
              'busNo': 'Bus 10',
              'forwardStops': ['Main Bus St', 'Sankaranpalayam'],
            }
          ]),
          200,
        );
      });

      final routes = await ApiService.fetchRoutes(client: client);

      expect(routes, hasLength(1));
      expect(routes.first.routeName, 'Sankaranpalayam');
      expect(routes.first.busNo, 'Bus 10');
      expect(routes.first.forwardStops, ['Main Bus St', 'Sankaranpalayam']);
    });

    test('returns an empty list for non-200 responses', () async {
      final client =
          MockClient((request) async => http.Response('bad request', 500));

      final routes = await ApiService.fetchRoutes(client: client);

      expect(routes, isEmpty);
    });
  });

  group('VehicleTrackingModel', () {
    test('parses ignition on/off from DB fields', () {
      final onModel = VehicleTrackingModel.fromJson({
        'routeId': 'route-1',
        'vehicleId': 'bus-7',
        'latitude': 12.9165,
        'longitude': 79.1325,
        'updatedAt': '2026-09-22T10:30:00Z',
        'ignitionStatus': 'ON',
      });

      final offModel = VehicleTrackingModel.fromJson({
        'routeId': 'route-1',
        'vehicleId': 'bus-7',
        'latitude': 12.9165,
        'longitude': 79.1325,
        'updatedAt': '2026-09-22T10:30:00Z',
        'engineOn': false,
      });

      expect(onModel.isIgnitionOn, isTrue);
      expect(offModel.isIgnitionOn, isFalse);
    });
  });
}
