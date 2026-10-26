class VehicleTrackingModel {
  final String routeId;
  final String vehicleId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final int? speedKph;
  final String? status;
  final bool isIgnitionOn;

  VehicleTrackingModel({
    required this.routeId,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.speedKph,
    this.status,
    this.isIgnitionOn = false,
  });

  bool get isTrackingActive => isIgnitionOn;

  static bool _parseIgnitionValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return false;
      if (normalized == 'true' || normalized == '1' || normalized == 'on') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'off') {
        return false;
      }
      return ['running', 'ignition_on', 'engine_on', 'active', 'started']
          .contains(normalized);
    }
    return false;
  }

  factory VehicleTrackingModel.fromJson(Map<String, dynamic> json) {
    final ignitionValue = json['ignitionOn'] ??
        json['ignition'] ??
        json['isIgnitionOn'] ??
        json['engineOn'] ??
        json['engine_status'] ??
        json['engineStatus'];
    print('DEBUG_IGNITION: $ignitionValue (${ignitionValue.runtimeType}) => ${_parseIgnitionValue(ignitionValue)}');

    return VehicleTrackingModel(
      routeId: json['routeId']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      latitude: (json['latitude'] is num
              ? json['latitude'] as num
              : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0)
          .toDouble(),
      longitude: (json['longitude'] is num
              ? json['longitude'] as num
              : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0)
          .toDouble(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      speedKph: json['speedKph'] is int
          ? json['speedKph'] as int
          : int.tryParse(json['speedKph']?.toString() ?? ''),
      status: json['status']?.toString() ?? json['rawStatus']?.toString(),
      isIgnitionOn: _parseIgnitionValue(ignitionValue),
    );
  }
}
