import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/route_model.dart';

class RestRepository {
  static const String baseUrl = 'https://selfrival-59aff-default-rtdb.europe-west1.firebasedatabase.app';

  // --- ROUTE METHODS (per-user) ---

  Future<List<AppRoute>> getRoutes(String uid) async {
    final response =
        await http.get(Uri.parse('$baseUrl/users/$uid/routes.json'));
    if (response.statusCode == 200) {
      if (response.body == 'null') return [];
      final Map<String, dynamic> data = json.decode(response.body);
      final List<AppRoute> routes = [];
      data.forEach((id, routeData) {
        routeData['id'] = id;
        routes.add(AppRoute.fromJson(routeData));
      });
      return routes;
    } else {
      throw Exception('Failed to load routes');
    }
  }

  Future<AppRoute> createRoute(String uid, AppRoute route) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$uid/routes.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(route.toJson()),
    );
    if (response.statusCode == 200) {
      final newId = json.decode(response.body)['name'] as String;
      return AppRoute(
        id: newId,
        name: route.name,
        distance: route.distance,
        elevationGain: route.elevationGain,
        circuit: route.circuit,
        activities: route.activities,
      );
    } else {
      throw Exception('Failed to upload route');
    }
  }

  Future<Activity> addActivity(
      String uid, String routeId, Activity activity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$uid/routes/$routeId/activities.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(activity.toJson()),
    );
    if (response.statusCode == 200) {
      final newId = json.decode(response.body)['name'] as String;
      return Activity(
        id: newId,
        avgSpeed: activity.avgSpeed,
        distance: activity.distance,
        time: activity.time,
        elevationGain: activity.elevationGain,
        date: activity.date,
        points: activity.points,
      );
    } else {
      throw Exception('Failed to save activity');
    }
  }

  Future<void> deleteRoute(String uid, String routeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$uid/routes/$routeId.json'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete route');
    }
  }

  // --- USER PROFILE ---
  Future<void> saveUserProfile(String uid, String name, String email) async {
    await http.patch(
      Uri.parse('$baseUrl/users/$uid/profile.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email}),
    );
  }
}