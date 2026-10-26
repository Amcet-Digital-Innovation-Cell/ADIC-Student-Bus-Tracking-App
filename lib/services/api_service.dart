import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/bus_model.dart';
import '../models/vehicle_tracking_model.dart';

class ApiService {
  static const String baseUrl = 'https://busappbackend.onrender.com';
  static const String endpoint = '/api/public/buses';
  static const String loginEndpoint = '/api/students/login';

  static const _storage = FlutterSecureStorage();
  static const String _keyStudentId = 'amcet_student_id';
  static const String _keyIsLoggedIn = 'amcet_is_logged_in';

  // verify credentials directly through render backend url
  static Future<Map<String, dynamic>> loginStudent({
    required String studentId,
    required String activationkey,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final cleanId = studentId.trim().toUpperCase();
    final cleanCode = activationkey.trim();

    try {
      final response = await httpClient
          .post(
            Uri.parse('$baseUrl$loginEndpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': cleanId,
              'activation_key': cleanCode,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _storage.write(key: _keyStudentId, value: cleanId);
        await _storage.write(key: _keyIsLoggedIn, value: 'true');

        if (data['student'] != null) {
          final student = data['student'];
          if (student['route_id'] != null || student['route_code'] != null) {
            await _storage.write(
              key: 'amcet_route_code',
              value: (student['route_id'] ?? student['route_code']).toString(),
            );
          }
          if (student['assigned_stop'] != null || student['stop_name'] != null) {
            await _storage.write(
              key: 'amcet_assigned_stop',
              value: (student['assigned_stop'] ?? student['stop_name']).toString(),
            );
          }
        }

        return {'success': true};
      }

      return {
        'success': false,
        'error': data['message'] ?? data['error'] ?? 'invalid credentials.',
      };
    } on TimeoutException {
      return {'success': false, 'error': 'render server timed out. please try again.'};
    } catch (e) {
      return {'success': false, 'error': 'unable to connect to render backend.'};
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  // Check if session is already saved
  static Future<bool> isLoggedIn() async {
    final status = await _storage.read(key: _keyIsLoggedIn);
    return status == 'true';
  }

  // Logout and clear credentials
  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Fetches routes along with their list of stops
  static Future<Map<String, List<String>>> fetchBusRoutesWithStops() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/public/buses'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded['data'] ?? decoded['routes'] ?? []);

        final Map<String, List<String>> routeMap = {};

        for (final item in list) {
          if (item is Map) {
            final name = (item['routeName'] ?? item['route_name'] ?? item['name'] ?? '').toString().trim();
            if (name.isNotEmpty) {
              final rawStops = item['forwardStops'] ?? item['stops'] ?? [];
              final List<String> stopsList = [];
              if (rawStops is List) {
                for (final s in rawStops) {
                  if (s != null && s.toString().trim().isNotEmpty) {
                    stopsList.add(s.toString().trim());
                  }
                }
              }
              routeMap[name] = stopsList;
            }
          }
        }
        return routeMap;
      }
      return const {};
    } catch (e) {
      debugPrint('[API Error fetchBusRoutesWithStops]: $e');
      return {};
    }
  }

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

  // Auto-fetch student name & year to verify student identity before registering
  static Future<Map<String, dynamic>> fetchStudentPreview(String studentId) async {
    final cleanId = studentId.trim().toUpperCase();
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/students/verify/$cleanId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final payload = data['data'] ?? data['student'] ?? data;
        
        // Backend keys mismatch aanaalum multiple common keys-ai check pannum
        final fetchedName = payload['student_name'] ??
            payload['studentname'] ??
            payload['name'] ??
            '';
        final fetchedAcademicYear = payload['academic_year'] ??
            payload['studying_year'] ??
            payload['year'] ??
            '';

        return {
          'success': true,
          'studentname': fetchedName.toString(),
          'year': fetchedAcademicYear.toString(),
        };
      }
      return {
        'success': false,
        'studentname': '',
        'year': '',
        'error': data['message'] ?? 'Student record not found.',
      };
    } catch (_) {
      return {
        'success': false,
        'studentname': '',
        'year': '',
        'error': 'Unable to connect to verification server.',
      };
    }
  }

  // Submit complete registration details and trigger email dispatch
  static Future<Map<String, dynamic>> registerStudent({
    required String studentId,
    required String studentName,
    required String academicYear,
    required String department,
    required String studentMobile,
    required String email,
    required String parentName,
    required String parentPhone,
    required String routeName,
    required String stopName,
  }) async {
    try {
      debugPrint('[API] Sending registration payload with routeName: $routeName');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/students/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': studentId.trim().toUpperCase(),
              'student_name': studentName.trim(),
              'academic_year': academicYear.trim(),
              'department': department.trim(),
              'student_mobile': studentMobile.trim(),
              'email': email.trim().toLowerCase(),
              'parent_name': parentName.trim(),
              'parent_phone': parentPhone.trim(),
              'route_name': routeName.trim(),
              'stop_name': stopName.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30));

    debugPrint('[API] Register Status Code: ${response.statusCode}');
    debugPrint('[API] Register Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Password sent via email.'};
      }
      return {
        'success': false,
        'error': data['message'] ?? data['error'] ?? 'Registration failed.',
      };
    } on TimeoutException {
      debugPrint('[API Error in registerStudent]: Request timed out after 30 seconds.');
      return {'success': false, 'error': 'Server timed out waiting for response.'};
    } catch (e) {
      debugPrint('[API Error in registerStudent]: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // FIXED: Pointing to /api/students/forgot-password instead of reset-password
  static Future<Map<String, dynamic>> forgotPassword(String studentId) async {
    final cleanId = studentId.trim().toUpperCase();

    debugPrint('--- [FORGOT PASSWORD API INITIATED] ---');
    debugPrint('[API] Target URL: $baseUrl/api/students/forgot-password');
    debugPrint('[API] Student ID Payload: $cleanId');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/students/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'student_id': cleanId}),
          )
          .timeout(const Duration(seconds: 40));

      debugPrint('[API] Forgot Password Status Code: ${response.statusCode}');
      debugPrint('[API] Forgot Password Raw Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('[API] Success: ${data['message']}');
        return {
          'success': true,
          'message': data['message'] ?? 'Password sent to your registered email.',
        };
      }

      debugPrint('[API] Rejection/Error Message: ${data['message'] ?? data['error']}');
      return {
        'success': false,
        'error': data['message'] ?? data['error'] ?? 'Failed to retrieve password.',
      };
    } on TimeoutException {
      debugPrint('[API Error]: Request timed out after 30 seconds.');
      return {'success': false, 'error': 'Server timed out. Please try again.'};
    } catch (e, stack) {
      debugPrint('[API Exception in forgotPassword]: $e');
      debugPrint('[API StackTrace]: $stack');
      return {'success': false, 'error': 'Unable to connect to server: $e'};
    }
  }
}