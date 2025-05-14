import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus.dart';
import '../services/location_service.dart';
import '../services/bus_service.dart';

class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});
  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? userLocation;
  Bus? selectedBus;
  List<Bus> searchResults = [];
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Bus>? _busTrackingSubscription;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool hasPermission = await LocationService.requestLocationPermission();
    if (hasPermission) {
      userLocation = await LocationService.getUserLocation();
      _startLocationTracking();
      setState(() {});
    }
  }

  void _startLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.getLocationStream().listen((position) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<void> _searchBuses(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final results = await BusService.searchBuses(query);
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching buses: $e')),
      );
    }
  }

  void _selectBus(Bus bus) {
    setState(() {
      selectedBus = bus;
      searchResults = [];
      _searchController.clear();
    });
    _startBusTracking(bus.id);
  }

  void _startBusTracking(String busId) {
    _busTrackingSubscription?.cancel();
    _busTrackingSubscription = BusService.trackBus(busId).listen((bus) {
      setState(() {
        selectedBus = bus;
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _busTrackingSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Bus Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (userLocation != null) {
                _mapController.move(userLocation!, 15);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bus number or route...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchBuses('');
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _searchBuses,
            ),
          ),
          if (searchResults.isNotEmpty)
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final bus = searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.directions_bus),
                    title: Text('Bus ${bus.number}'),
                    subtitle: Text('${bus.startPoint} → ${bus.endPoint}'),
                    onTap: () => _selectBus(bus),
                  );
                },
              ),
            ),
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: userLocation ?? const LatLng(12.9716, 77.5946),
                zoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                if (userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                      ),
                    ],
                  ),
                if (selectedBus != null) ...[
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedBus!.currentLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.directions_bus, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: selectedBus!.routePoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
