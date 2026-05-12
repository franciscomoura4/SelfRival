import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/route_model.dart';
import 'models/user_model.dart';

class RestRepository {

  static const String baseUrl = 'https://selfrival-59aff-default-rtdb.europe-west1.firebasedatabase.app';

  // --- ROUTE METHODS ---
  Future<List<RouteMaster>> getRoutes() async {
    final response = await http.get(Uri.parse('$baseUrl/routes.json'));
    if (response.statusCode == 200) {
      if (response.body == 'null') return [];
      final Map<String, dynamic> data = json.decode(response.body);
      final List<RouteMaster> routes = [];
      data.forEach((id, routeData) {
        routeData['id'] = id;
        routes.add(RouteMaster.fromJson(routeData));
      });
      return routes;
    } else {
      throw Exception('Failed to load routes');
    }
  }

  Future<RouteMaster> createRoute(RouteMaster route) async {
    final response = await http.post(
      Uri.parse('$baseUrl/routes.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(route.toJson()),
    );
    if (response.statusCode == 200) {
      final newId = json.decode(response.body)['name'];
      return RouteMaster(id: newId, name: route.name, distance: route.distance, personalBestTime: route.personalBestTime, elevationGain: route.elevationGain, points: route.points);
    } else {
      throw Exception('Failed to upload route');
    }
  }

  // Update an existing route if they beat their PB!
  Future<void> updateRoutePB(String routeId, double newBestTime) async {
    await http.patch(
      Uri.parse('$baseUrl/routes/$routeId.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'personalBestTime': newBestTime}),
    );
  }

  // --- USER LOGIC (MOCK AUTH TO FIREBASE) ---
  Future<AppUser> loginOrCreateUser(String email, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'name': name}),
    );
    if (response.statusCode == 200) {
      return AppUser(id: json.decode(response.body)['name'], name: name, email: email);
    } else {
      throw Exception('Failed to auth user');
    }
  }
}