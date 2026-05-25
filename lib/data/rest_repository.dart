import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'models/route_model.dart';

class RestRepository {
  static const String baseUrl = 'https://selfrival-59aff-default-rtdb.europe-west1.firebasedatabase.app';

  // Helper for consistent error handling
  Future<http.Response> _safeGet(Uri uri) async {
    try {
      return await http.get(uri).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on TimeoutException {
      throw Exception('Connection timed out. Please try again.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _safePost(Uri uri, Map<String, String> headers, String body) async {
    try {
      return await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('No internet connection. Unable to save data.');
    } on TimeoutException {
      throw Exception('Server request timed out.');
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  Future<http.Response> _safePatch(Uri uri, Map<String, String> headers, String body) async {
    try {
      return await http.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('No internet connection.');
    } on TimeoutException {
      throw Exception('Request timed out.');
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  Future<http.Response> _safeDelete(Uri uri) async {
    try {
      return await http.delete(uri).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('No internet connection. Unable to delete.');
    } on TimeoutException {
      throw Exception('Delete request timed out.');
    } catch (e) {
      throw Exception('Failed to delete: $e');
    }
  }

  // --- ROUTE METHODS (per-user) ---

  Future<List<AppRoute>> getRoutes(String uid) async {
    final response = await _safeGet(Uri.parse('$baseUrl/users/$uid/routes.json'));
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
      throw Exception('Server returned error ${response.statusCode}');
    }
  }

  Future<AppRoute> createRoute(String uid, AppRoute route) async {
    final response = await _safePost(
      Uri.parse('$baseUrl/users/$uid/routes.json'),
      {'Content-Type': 'application/json'},
      json.encode(route.toJson()),
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
      throw Exception('Failed to create route (Error ${response.statusCode})');
    }
  }

  Future<Activity> addActivity(
      String uid, String routeId, Activity activity) async {
    final response = await _safePost(
      Uri.parse('$baseUrl/users/$uid/routes/$routeId/activities.json'),
      {'Content-Type': 'application/json'},
      json.encode(activity.toJson()),
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
      throw Exception('Failed to save activity (Error ${response.statusCode})');
    }
  }

  Future<void> deleteRoute(String uid, String routeId) async {
    final response = await _safeDelete(
      Uri.parse('$baseUrl/users/$uid/routes/$routeId.json'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete route (Error ${response.statusCode})');
    }
  }

  // --- USER PROFILE ---
  Future<void> saveUserProfile(String uid, String name, String email) async {
    await _safePatch(
      Uri.parse('$baseUrl/users/$uid/profile.json'),
      {'Content-Type': 'application/json'},
      json.encode({'name': name, 'email': email}),
    );
  }
}