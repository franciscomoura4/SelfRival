import 'package:latlong2/latlong.dart';

class RoutePoint {
  final LatLng position;
  final double timestamp;
  final double distance;
  final double altitude;

  RoutePoint({
    required this.position,
    required this.timestamp,
    required this.distance,
    required this.altitude,
  });

  factory RoutePoint.fromJson(Map<dynamic, dynamic> json) {
    return RoutePoint(
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      timestamp: (json['timestamp'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': timestamp,
      'distance': distance,
      'altitude': altitude,
    };
  }
}

class RouteMaster {
  final String id;
  final String name;
  final double distance;
  final double personalBestTime;
  final double elevationGain;
  final List<RoutePoint> points;

  RouteMaster({
    required this.id,
    required this.name,
    required this.distance,
    required this.personalBestTime,
    required this.elevationGain,
    required this.points,
  });

  List<LatLng> get path => points.map((p) => p.position).toList();

  factory RouteMaster.fromJson(Map<dynamic, dynamic> json) {
    var pointsData = json['points'] as List? ?? json['path'] as List? ?? [];
    List<RoutePoint> parsedPoints = [];

    for (int i = 0; i < pointsData.length; i++) {
      var p = pointsData[i];
      if (p.containsKey('timestamp')) {
        parsedPoints.add(RoutePoint.fromJson(p));
      } else {
        parsedPoints.add(RoutePoint(
          position: LatLng(p['lat'], p['lng']),
          timestamp: 0.0,
          distance: 0.0,
          altitude: 0.0,
        ));
      }
    }

    return RouteMaster(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Route',
      distance: (json['distance'] as num).toDouble(),
      personalBestTime: (json['personalBestTime'] as num).toDouble(),
      elevationGain: (json['elevationGain'] as num?)?.toDouble() ?? 0.0,
      points: parsedPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'distance': distance,
      'personalBestTime': personalBestTime,
      'elevationGain': elevationGain,
      'points': points.map((p) => p.toJson()).toList(),
    };
  }
}