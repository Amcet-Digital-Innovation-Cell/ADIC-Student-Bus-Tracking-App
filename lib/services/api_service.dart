import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bus_model.dart';
import '../models/vehicle_tracking_model.dart';

class ApiService {
  // ── URL per target ────────────────────────────────────────────────────────
  // Windows desktop / Chrome / Edge (flutter run on PC): http://localhost:3001
  // Android Emulator:                                    http://10.0.2.2:3001
  // Physical Android/iOS device (same Wi-Fi as PC):     http://10.228.166.103:3001
  static const String baseUrl = 'http://localhost:3001';
  static const String endpoint = '/api/public/buses';

  static Future<List<BusRouteModel>> fetchRoutes({
    http.Client? client,
    String baseUrlOverride = baseUrl,
    String endpointOverride = endpoint,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient
          .get(Uri.parse('$baseUrlOverride$endpointOverride'))
          .timeout(timeout);

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['data'] ?? decoded['routes'];
        if (payload is! List) {
          return [];
        }
        return _parseRoutes(payload);
      }

      if (decoded is! List) {
        return [];
      }

      return _parseRoutes(decoded);
    } on TimeoutException {
      return [];
    } catch (_) {
      return [];
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  static Future<VehicleTrackingModel?> fetchVehicleTracking({
    required String routeId,
    String mode = 'morning',
    http.Client? client,
    String baseUrlOverride = baseUrl,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final httpClient = client ?? http.Client();
    final trackingEndpoint = '/api/public/buses/$routeId/tracking';

    try {
      final uri = Uri.parse('$baseUrlOverride$trackingEndpoint').replace(
        queryParameters: {
          if (mode.isNotEmpty) 'mode': mode,
        },
      );
      final response = await httpClient.get(uri).timeout(timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! Map<String, dynamic>) {
        return null;
      }

      return VehicleTrackingModel.fromJson(data);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  static List<BusRouteModel> _parseRoutes(List<dynamic> payload) {
    return payload.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Unexpected route payload');
      }

      return BusRouteModel(
        id: item['id']?.toString() ?? '',
        routeName: item['routeName']?.toString() ?? '',
        busNo: item['busNo']?.toString() ?? '',
        forwardStops: List<String>.from(item['forwardStops'] ?? const []),
      );
    }).toList();
  }
}
