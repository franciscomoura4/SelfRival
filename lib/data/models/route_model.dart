import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteMaster {
  final String id;
  final String name;
  final double distance;
  final double personalBestTime;
  final List<LatLng> path;

  RouteMaster({
    required this.id,
    required this.name,
    required this.distance,
    required this.personalBestTime,
    required this.path,
  });

  factory RouteMaster.fromJson(Map<dynamic, dynamic> json) {
    var pathList = json['path'] as List? ?? [];
    List<LatLng> parsedPath = pathList.map((p) => LatLng(p['lat'], p['lng'])).toList();

    return RouteMaster(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Route',
      distance: (json['distance'] as num).toDouble(),
      personalBestTime: (json['personalBestTime'] as num).toDouble(),
      path: parsedPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'distance': distance,
      'personalBestTime': personalBestTime,
      'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    };
  }
}