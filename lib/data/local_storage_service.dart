import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/route_model.dart';

class LocalStorageService {
  static const String _routesKey = 'cached_routes_';

  static Future<void> saveRoutes(String uid, List<AppRoute> routes) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(routes.map((r) => r.toJson()).toList());
    await prefs.setString('$_routesKey$uid', data);
  }

  static Future<List<AppRoute>> loadRoutes(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('$_routesKey$uid');
      if (data == null) return [];
      
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((json) => AppRoute.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      return [];
    }
  }
}
