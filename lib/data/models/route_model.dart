class RouteMaster {
  final String id;
  final String name;
  final String geometry; // Will hold polyline coordinates later
  final double personalBestTime; // In seconds
  final double distance; // In km

  RouteMaster({
    required this.id,
    required this.name,
    required this.geometry,
    required this.personalBestTime,
    required this.distance,
  });
}

class RunActivity {
  final String id;
  final double avgSpeed;
  final double distance;
  final double time; // In seconds
  final String? routeId; // Nullable FK to RouteMaster

  RunActivity({
    required this.id,
    required this.avgSpeed,
    required this.distance,
    required this.time,
    this.routeId,
  });
}