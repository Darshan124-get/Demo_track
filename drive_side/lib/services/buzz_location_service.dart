import 'dart:convert';
import 'package:http/http.dart' as http;

class BuzzLocationService {
  static Future<bool> sendLocation(String busId, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend-url.com/api/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'busId': busId,
          'lat': lat,
          'lng': lng,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
