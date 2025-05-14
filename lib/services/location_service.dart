import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/stage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<LatLng> getUserLocation() async {
    Position position = await getCurrentLocation();
    return LatLng(position.latitude, position.longitude);
  }

  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  static Future<LatLng> getBusLocation() async {
    final response = await http.get(Uri.parse("https://yourserver.com/bus_location"));
    final data = json.decode(response.body);
    return LatLng(data['lat'], data['lng']);
  }

  static Future<List<LatLng>> getPolylinePoints() async {
    return [
      LatLng(12.9716, 77.5946),
      LatLng(12.9720, 77.5950),
      LatLng(12.9750, 77.5970),
      LatLng(12.9780, 77.5985),
    ];
  }

  static Future<List<Stage>> getNearbyStages(LatLng currentLocation) async {
    return [
      Stage(name: "Stage 1", location: LatLng(12.9720, 77.5950)),
      Stage(name: "Stage 2", location: LatLng(12.9750, 77.5970)),
    ];
  }
}
