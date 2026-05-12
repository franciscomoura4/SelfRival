import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/models/route_model.dart';

class TrackingState {
  final List<RoutePoint> trackedPoints;
  final double totalDistance; // in meters
  final double currentPace; // seconds per km
  final double elevationGain;
  final Duration elapsedTime;
  final bool isTracking;
  final Set<int> passedCheckpoints;
  final bool isOffRoute;
  final bool isRouteCompleted;

  TrackingState({
    this.trackedPoints = const [],
    this.totalDistance = 0.0,
    this.currentPace = 0.0,
    this.elevationGain = 0.0,
    this.elapsedTime = Duration.zero,
    this.isTracking = false,
    this.passedCheckpoints = const {},
    this.isOffRoute = false,
    this.isRouteCompleted = false,
  });

  TrackingState copyWith({
    List<RoutePoint>? trackedPoints,
    double? totalDistance,
    double? currentPace,
    double? elevationGain,
    Duration? elapsedTime,
    bool? isTracking,
    Set<int>? passedCheckpoints,
    bool? isOffRoute,
    bool? isRouteCompleted,
  }) {
    return TrackingState(
      trackedPoints: trackedPoints ?? this.trackedPoints,
      totalDistance: totalDistance ?? this.totalDistance,
      currentPace: currentPace ?? this.currentPace,
      elevationGain: elevationGain ?? this.elevationGain,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isTracking: isTracking ?? this.isTracking,
      passedCheckpoints: passedCheckpoints ?? this.passedCheckpoints,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      isRouteCompleted: isRouteCompleted ?? this.isRouteCompleted,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  final FlutterTts _tts = FlutterTts();
  RouteMaster? _targetRoute;
  bool _hasStartedMoving = false;

  TrackingNotifier() : super(TrackingState());

  Future<void> startTracking({RouteMaster? targetRoute}) async {
    _targetRoute = targetRoute;
    _hasStartedMoving = false;

    state = TrackingState(isTracking: true);
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen(_handlePositionUpdate);
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isTracking) {
        state = state.copyWith(elapsedTime: state.elapsedTime + const Duration(seconds: 1));
      }
    });
  }

  void _handlePositionUpdate(Position position) {
    if (!state.isTracking) return;

    // 🟢 IMPROVED START DETECTION: 
    // Emulators often have 0 speed, so we check distance too.
    bool shouldStart = false;
    if (!_hasStartedMoving) {
      if (position.speed > 0.3) {
        shouldStart = true;
      } else if (state.trackedPoints.isNotEmpty) {
        double distFromStart = Geolocator.distanceBetween(
          state.trackedPoints.first.position.latitude,
          state.trackedPoints.first.position.longitude,
          position.latitude,
          position.longitude,
        );
        if (distFromStart > 5) shouldStart = true;
      } else {
        // First point ever - record it as the potential start
        List<RoutePoint> initialPoints = [RoutePoint(
          position: LatLng(position.latitude, position.longitude),
          timestamp: 0,
          distance: 0,
          altitude: position.altitude,
        )];
        state = state.copyWith(trackedPoints: initialPoints);
      }
    }

    if (!_hasStartedMoving && shouldStart) {
      _hasStartedMoving = true;
      _startTimer();
      _speakFeedback("Run started!");
    }

    if (!_hasStartedMoving) return;

    // Use a local copy of the current state variables to avoid race conditions
    // during the synchronous execution of this method.
    final currentElapsedTime = state.elapsedTime;
    List<RoutePoint> updatedPoints = List.from(state.trackedPoints);
    double addedDistance = 0.0;
    double addedElevation = 0.0;

    if (updatedPoints.isNotEmpty) {
      final lastPoint = updatedPoints.last;
      addedDistance = Geolocator.distanceBetween(
        lastPoint.position.latitude,
        lastPoint.position.longitude,
        position.latitude,
        position.longitude,
      );
      
      if (position.altitude > lastPoint.altitude) {
        addedElevation = position.altitude - lastPoint.altitude;
      }
    }

    final newDistance = state.totalDistance + addedDistance;
    final newPoint = RoutePoint(
      position: LatLng(position.latitude, position.longitude),
      timestamp: currentElapsedTime.inSeconds.toDouble(),
      distance: newDistance,
      altitude: position.altitude,
    );
    updatedPoints.add(newPoint);

    // Calculate Pace
    double currentPace = 0.0;
    if (currentElapsedTime.inSeconds > 0 && newDistance > 0) {
      currentPace = (currentElapsedTime.inSeconds / (newDistance / 1000));
    }

    bool isOffRoute = false;
    bool isRouteCompleted = state.isRouteCompleted;
    Set<int> updatedCheckpoints = Set.from(state.passedCheckpoints);

    if (_targetRoute != null && _targetRoute!.points.isNotEmpty) {
      isOffRoute = _checkOffRoute(position);
      if (isOffRoute && !state.isOffRoute) {
        _speakFeedback("Off route. Head back.");
      } else if (!isOffRoute && state.isOffRoute) {
        _speakFeedback("Back on track.");
      }

      int? newCheckpointIndex = _checkCheckpoints(position, updatedCheckpoints);
      if (newCheckpointIndex != null) {
        updatedCheckpoints.add(newCheckpointIndex);
        int totalCheckpoints = 10;
        if (updatedCheckpoints.length == totalCheckpoints + 1) {
          isRouteCompleted = true;
          _speakFeedback("Route completed.");
          _timer?.cancel();
          _positionSubscription?.cancel();
        }
      }
    }

    state = state.copyWith(
      trackedPoints: updatedPoints,
      totalDistance: newDistance,
      currentPace: currentPace,
      elevationGain: state.elevationGain + addedElevation,
      passedCheckpoints: updatedCheckpoints,
      isOffRoute: isOffRoute,
      isRouteCompleted: isRouteCompleted,
      isTracking: !isRouteCompleted,
      elapsedTime: currentElapsedTime, // 🟢 Keep current time to prevent overwrite
    );
  }

  int? _checkCheckpoints(Position current, Set<int> passed) {
    if (_targetRoute == null) return null;
    int numIntermediates = 10;
    int step = (_targetRoute!.points.length / numIntermediates).clamp(1, 1000).toInt();
    for (int i = 0; i < _targetRoute!.points.length - 1; i += step) {
      if (passed.contains(i)) continue;
      final p = _targetRoute!.points[i];
      double d = Geolocator.distanceBetween(
        current.latitude, current.longitude,
        p.position.latitude, p.position.longitude
      );
      if (d < 25) return i; 
    }
    int lastIdx = _targetRoute!.points.length - 1;
    if (!passed.contains(lastIdx)) {
      final lastPoint = _targetRoute!.points[lastIdx];
      double d = Geolocator.distanceBetween(
        current.latitude, current.longitude,
        lastPoint.position.latitude, lastPoint.position.longitude
      );
      if (d < 30) return lastIdx;
    }
    return null;
  }

  bool _checkOffRoute(Position current) {
    if (_targetRoute == null) return false;
    double minDistance = double.infinity;
    for (var p in _targetRoute!.points) {
      double d = Geolocator.distanceBetween(
        current.latitude, current.longitude,
        p.position.latitude, p.position.longitude
      );
      if (d < minDistance) minDistance = d;
    }
    return minDistance > 50;
  }

  Future<void> _speakFeedback(String message) async {
    try {
      await _tts.speak(message);
    } catch (e) {
      // ignore
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _timer?.cancel();
    state = state.copyWith(isTracking: false);
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});
