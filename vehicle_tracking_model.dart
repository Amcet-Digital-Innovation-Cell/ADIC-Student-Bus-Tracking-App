class VehicleTrackingModel {
  final String routeId;
  final String vehicleId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final int? speedKph;
  final String? status;

  VehicleTrackingModel({
    required this.routeId,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.speedKph,
    this.status,
  });

  factory VehicleTrackingModel.fromJson(Map<String, dynamic> json) {
    return VehicleTrackingModel(
      routeId: json['routeId']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      latitude: (json['latitude'] is num ? json['latitude'] as num : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0).toDouble(),
      longitude: (json['longitude'] is num ? json['longitude'] as num : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0).toDouble(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      speedKph: json['speedKph'] is int ? json['speedKph'] as int : int.tryParse(json['speedKph']?.toString() ?? ''),
      status: json['status']?.toString(),
    );
  }
}
