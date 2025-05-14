import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bus.dart';
import 'package:latlong2/latlong.dart';

class BusService {
  static const String baseUrl = 'https://yourserver.com/api'; // Replace with your actual API endpoint

  static Future<List<Bus>> searchBuses(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Bus.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load buses');
      }
    } catch (e) {
      throw Exception('Error searching buses: $e');
    }
  }

  static Future<Bus> getBusDetails(String busId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses/$busId'),
      );

      if (response.statusCode == 200) {
        return Bus.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load bus details');
      }
    } catch (e) {
      throw Exception('Error getting bus details: $e');
    }
  }

  static Stream<Bus> trackBus(String busId) async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/buses/$busId/track'),
        );

        if (response.statusCode == 200) {
          yield Bus.fromJson(json.decode(response.body));
        }
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        print('Error tracking bus: $e');
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }
} 