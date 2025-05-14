import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/buzz_location_service.dart';

class BuzzShareScreen extends StatefulWidget {
  const BuzzShareScreen({super.key});

  @override
  State<BuzzShareScreen> createState() => _BuzzShareScreenState();
}

class _BuzzShareScreenState extends State<BuzzShareScreen> {
  final TextEditingController _busIdController = TextEditingController();
  bool isSharing = false;
  Timer? _timer;
  String status = 'Not sharing';
  bool isLoading = false;
  Position? lastPosition;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        status = 'Location services are disabled';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          status = 'Location permissions are denied';
        });
        return;
      }
    }
  }

  void _toggleSharing(bool value) async {
    if (_busIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Bus ID'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSharing = value;
      isLoading = true;
    });

    if (value) {
      await _startSharing();
    } else {
      _stopSharing();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _startSharing() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        lastPosition = pos;
      });
      
      bool success = await BuzzLocationService.sendLocation(
        _busIdController.text.trim(),
        pos.latitude,
        pos.longitude,
      );

      if (success) {
        _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
          try {
            Position newPos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            setState(() {
              lastPosition = newPos;
            });
            
            success = await BuzzLocationService.sendLocation(
              _busIdController.text.trim(),
              newPos.latitude,
              newPos.longitude,
            );
            
            if (!success) {
              _stopSharing();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to send location. Sharing stopped.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } catch (e) {
            _stopSharing();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        });
      } else {
        setState(() {
          status = 'Failed to start sharing';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Error: ${e.toString()}';
      });
    }
  }

  void _stopSharing() {
    _timer?.cancel();
    setState(() {
      status = "Stopped sharing";
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _busIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BuzzSide - Driver'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _busIdController,
                        decoration: const InputDecoration(
                          labelText: 'Bus ID',
                          hintText: 'Enter your bus identification number',
                          prefixIcon: Icon(Icons.directions_bus),
                        ),
                        enabled: !isSharing,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Sharing',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Share Live Location'),
                        subtitle: Text(
                          isSharing ? 'Sharing active' : 'Sharing inactive',
                          style: TextStyle(
                            color: isSharing ? Colors.green : Colors.grey,
                          ),
                        ),
                        value: isSharing,
                        onChanged: isLoading ? null : _toggleSharing,
                      ),
                      if (lastPosition != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Last Location:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Latitude: ${lastPosition!.latitude.toStringAsFixed(6)}\nLongitude: ${lastPosition!.longitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
