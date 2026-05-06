import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/route_model.dart';

class RestRepository {

  static const String baseUrl = 'https://selfrival-59aff-default-rtdb.europe-west1.firebasedatabase.app';

  Future<List<RouteMaster>> getRoutes() async {
    final response = await http.get(Uri.parse('$baseUrl/routes.json'));

    if (response.statusCode == 200) {
      if (response.body == 'null') return [];

      final Map<String, dynamic> data = json.decode(response.body);
      final List<RouteMaster> routes = [];

      data.forEach((firebaseId, routeData) {
        routeData['id'] = firebaseId;
        routes.add(RouteMaster.fromJson(routeData));
      });

      return routes;
    } else {
      throw Exception('Failed to load routes from Firebase');
    }
  }

  Future<RouteMaster> createRoute(RouteMaster route) async {
    final response = await http.post(
      Uri.parse('$baseUrl/routes.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(route.toJson()),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final newFirebaseId = responseData['name'];

      return RouteMaster(
        id: newFirebaseId,
        name: route.name,
        distance: route.distance,
        personalBestTime: route.personalBestTime,
        path: route.path,
      );
    } else {
      throw Exception('Failed to upload route to Firebase');
    }
  }
}