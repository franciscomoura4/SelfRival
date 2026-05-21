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

class Activity {
  final String id;
  final double avgSpeed; // km/h
  final double distance; // km
  final double time; // seconds
  final double elevationGain;
  final DateTime date;
  final List<RoutePoint> points;

  Activity({
    required this.id,
    required this.avgSpeed,
    required this.distance,
    required this.time,
    required this.elevationGain,
    required this.date,
    required this.points,
  });

  factory Activity.fromJson(Map<dynamic, dynamic> json) {
    final pointsData = json['points'] as List? ?? [];
    final parsedPoints = pointsData
        .map((p) => RoutePoint.fromJson(p as Map<dynamic, dynamic>))
        .toList();

    return Activity(
      id: json['id'] as String? ?? '',
      avgSpeed: (json['avgSpeed'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      time: (json['time'] as num?)?.toDouble() ?? 0.0,
      elevationGain: (json['elevationGain'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      points: parsedPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgSpeed': avgSpeed,
      'distance': distance,
      'time': time,
      'elevationGain': elevationGain,
      'date': date.toIso8601String(),
      'points': points.map((p) => p.toJson()).toList(),
    };
  }
}

class AppRoute {
  final String id;
  final String name;
  final List<RoutePoint> circuit; // canonical GPS path of this route
  final double distance; // km
  final double elevationGain;
  final List<Activity> activities; // sorted: most recent first

  AppRoute({
    required this.id,
    required this.name,
    required this.circuit,
    required this.distance,
    required this.elevationGain,
    required this.activities,
  });

  List<LatLng> get path => circuit.map((p) => p.position).toList();

  double get personalBestTime => activities.isEmpty
      ? 0.0
      : activities.map((a) => a.time).reduce((a, b) => a < b ? a : b);

  factory AppRoute.fromJson(Map<dynamic, dynamic> json) {
    // Support both 'circuit' (new) and 'points' (legacy) keys
    final circuitData =
        (json['circuit'] ?? json['points'] ?? json['path']) as List? ?? [];
    final parsedCircuit = <RoutePoint>[];
    for (final p in circuitData) {
      if (p is Map) {
        final pp = Map<dynamic, dynamic>.from(p);
        parsedCircuit.add(
          pp.containsKey('timestamp')
              ? RoutePoint.fromJson(pp)
              : RoutePoint(
                  position: LatLng(
                    (pp['lat'] as num).toDouble(),
                    (pp['lng'] as num).toDouble(),
                  ),
                  timestamp: 0.0,
                  distance: 0.0,
                  altitude: 0.0,
                ),
        );
      }
    }

    // Parse nested activities map from Firebase
    final parsedActivities = <Activity>[];
    final activitiesData = json['activities'];
    if (activitiesData is Map) {
      activitiesData.forEach((id, actData) {
        if (actData is Map) {
          final actMap = Map<dynamic, dynamic>.from(actData);
          actMap['id'] = id;
          parsedActivities.add(Activity.fromJson(actMap));
        }
      });
      parsedActivities.sort((a, b) => b.date.compareTo(a.date));
    }

    return AppRoute(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Route',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      elevationGain: (json['elevationGain'] as num?)?.toDouble() ?? 0.0,
      circuit: parsedCircuit,
      activities: parsedActivities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'distance': distance,
      'elevationGain': elevationGain,
      'circuit': circuit.map((p) => p.toJson()).toList(),
    };
  }
}