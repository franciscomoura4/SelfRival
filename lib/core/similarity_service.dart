import 'package:geolocator/geolocator.dart';
import '../data/models/route_model.dart';

/// Determines whether an activity's GPS trace is similar enough to a route's
/// canonical circuit to belong to that route.
///
/// Strategy: for each activity point, check if any circuit point lies within
/// [_toleranceMeters]. If ≥ [_threshold] fraction of activity points match,
/// the paths are considered similar.
class SimilarityService {
  static const double _toleranceMeters = 30.0;
  static const double _threshold = 0.70;

  static bool isSimilar(
    List<RoutePoint> activityPoints,
    List<RoutePoint> routeCircuit,
  ) {
    if (activityPoints.isEmpty || routeCircuit.isEmpty) return false;

    int matchCount = 0;
    for (final ap in activityPoints) {
      for (final rp in routeCircuit) {
        final d = Geolocator.distanceBetween(
          ap.position.latitude,
          ap.position.longitude,
          rp.position.latitude,
          rp.position.longitude,
        );
        if (d <= _toleranceMeters) {
          matchCount++;
          break;
        }
      }
    }

    return matchCount / activityPoints.length >= _threshold;
  }
}
