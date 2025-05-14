import 'package:latlong2/latlong.dart';

class Bus {
  final String id;
  final String number;
  final String routeName;
  final LatLng currentLocation;
  final List<LatLng> routePoints;
  final String startPoint;
  final String endPoint;
  final bool isActive;

  Bus({
    required this.id,
    required this.number,
    required this.routeName,
    required this.currentLocation,
    required this.routePoints,
    required this.startPoint,
    required this.endPoint,
    this.isActive = true,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      number: json['number'],
      routeName: json['routeName'],
      currentLocation: LatLng(
        json['currentLocation']['latitude'],
        json['currentLocation']['longitude'],
      ),
      routePoints: (json['routePoints'] as List).map((point) => LatLng(
        point['latitude'],
        point['longitude'],
      )).toList(),
      startPoint: json['startPoint'],
      endPoint: json['endPoint'],
      isActive: json['isActive'] ?? true,
    );
  }
} 