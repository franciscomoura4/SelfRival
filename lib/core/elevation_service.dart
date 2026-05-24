import 'dart:convert';
import 'package:http/http.dart' as http;

class ElevationService {
  static Future<double?> getElevation(double lat, double lng) async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/elevation?latitude=$lat&longitude=$lng');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['elevation'] != null && data['elevation'] is List && (data['elevation'] as List).isNotEmpty) {
          return (data['elevation'][0] as num).toDouble();
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}
