class BusRouteModel {
  final String id;
  final String routeName;
  final String busNo;
  final List<String> forwardStops; // Morning order: Hometown -> College

  BusRouteModel({
    required this.id,
    required this.routeName,
    required this.busNo,
    required this.forwardStops,
  });

  // Automatically reverses the array when evening mode is active
  List<String> getStops(bool isEveningReturn) {
    if (isEveningReturn) {
      return forwardStops.reversed.toList();
    }
    return forwardStops;
  }
}