import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  final double? ghostTimeDelta; // NEW: Visual Coach (- is ahead, + is behind)

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
    this.ghostTimeDelta,
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
    double? ghostTimeDelta,
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
      ghostTimeDelta: ghostTimeDelta ?? this.ghostTimeDelta,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  final FlutterTts _tts = FlutterTts();
  RouteMaster? _targetRoute;
  bool _hasStartedMoving = false;
  double _lastPacingFeedbackDistance = 0;
  int _lastPaceFeedbackKm = 0;

  TrackingNotifier() : super(TrackingState());

  Future<void> startTracking({RouteMaster? targetRoute}) async {
    _targetRoute = targetRoute;
    _hasStartedMoving = false;
    _lastPacingFeedbackDistance = 0;
    _lastPaceFeedbackKm = 0;

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
      _speakFeedback("Run started! Push your limits.");
    }

    if (!_hasStartedMoving) return;

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

    // Instantaneous pace for better dashboard accuracy
    double currentPace = 0.0;
    if (addedDistance > 0) {
      // pace in seconds per km based on the latest movement tick
      currentPace = (1 / (addedDistance / 1000)); // 1 second per X km
    } else if (currentElapsedTime.inSeconds > 0 && newDistance > 0) {
      currentPace = (currentElapsedTime.inSeconds / (newDistance / 1000));
    }

    _checkPaceFeedback(newDistance, currentPace);

    // LIVE COACH DELTA LOGIC
    double? currentDelta;
    if (_targetRoute != null && _targetRoute!.points.isNotEmpty && newDistance > 0) {
      double ghostTime = _getGhostTimeAtDistance(newDistance);
      if (ghostTime > 0) {
        currentDelta = currentElapsedTime.inSeconds.toDouble() - ghostTime;
      }
      _checkPacingAudioCoach(newDistance, currentDelta);
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
        if (updatedCheckpoints.length >= totalCheckpoints) {
          isRouteCompleted = true;
          _speakFeedback("Route completed. Outstanding job!");
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
      elapsedTime: currentElapsedTime,
      ghostTimeDelta: currentDelta,
    );
  }

  void _checkPaceFeedback(double distance, double pace) {
    int currentKm = (distance / 1000).floor();
    if (currentKm > _lastPaceFeedbackKm) {
      _lastPaceFeedbackKm = currentKm;
      int minutes = (pace / 60).floor();
      int seconds = (pace % 60).round();
      _speakFeedback("Kilometer $currentKm. Pace is $minutes minutes and $seconds seconds per kilometer.");
    }
  }

  void _checkPacingAudioCoach(double distance, double? delta) {
    if (delta == null || distance - _lastPacingFeedbackDistance < 500) return;
    _lastPacingFeedbackDistance = distance;

    if (delta.abs() < 5) {
      _speakFeedback("You are neck and neck with your personal best.");
    } else if (delta < 0) {
      _speakFeedback("You are ${delta.abs().toInt()} seconds ahead of your ghost. Keep it up!");
    } else {
      _speakFeedback("You are ${delta.toInt()} seconds behind. Pick up the pace!");
    }
  }

  double _getGhostTimeAtDistance(double distance) {
    final points = _targetRoute!.points;
    if (points.isEmpty) return 0;
    if (distance >= points.last.distance) return points.last.timestamp;

    for (int i = 0; i < points.length - 1; i++) {
      if (distance >= points[i].distance && distance <= points[i+1].distance) {
        double d1 = points[i].distance;
        double d2 = points[i+1].distance;
        double t1 = points[i].timestamp;
        double t2 = points[i+1].timestamp;

        if (d2 == d1) return t1;
        return t1 + (t2 - t1) * (distance - d1) / (d2 - d1);
      }
    }
    return 0;
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