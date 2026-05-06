import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteMaster {
  final String id;
  final String name;
  final double distance;
  final double personalBestTime;
  final double elevationGain; // 🟢 NEW: Strava-style altitude!
  final List<LatLng> path;

  RouteMaster({
    required this.id,
    required this.name,
    required this.distance,
    required this.personalBestTime,
    required this.elevationGain,
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
      // Use ?? 0.0 so old runs without elevation don't crash the app!
      elevationGain: (json['elevationGain'] as num?)?.toDouble() ?? 0.0,
      path: parsedPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'distance': distance,
      'personalBestTime': personalBestTime,
      'elevationGain': elevationGain,
      'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    };
  }
}