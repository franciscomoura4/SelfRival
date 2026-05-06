import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteMaster {
  final String id;
  final String name;
  final double distance;
  final double personalBestTime;
  final List<LatLng> path; // <-- This is the new magic property!

  RouteMaster({
    required this.id,
    required this.name,
    required this.distance,
    required this.personalBestTime,
    required this.path,
  });
}