import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../data/models/route_model.dart';

class RunScreen extends ConsumerStatefulWidget {
  final String? routeId;
  const RunScreen({super.key, this.routeId});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  final List<LatLng> _currentPath = [];
  double _totalDistanceKm = 0.0;
  double _elevationGain = 0.0;
  double? _lastAltitude;
  int _secondsElapsed = 0;
  Timer? _timer;

  RouteMaster? _targetRoute;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(targetRouteIdProvider.notifier).state = widget.routeId;
      if (widget.routeId != null) {
        final routes = ref.read(routeProvider).value ?? [];
        _targetRoute = routes.firstWhere((r) => r.id == widget.routeId);
      }
    });
    _startRun();
  }

  void _startRun() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          if (_currentPath.isNotEmpty) {
            final lastPoint = _currentPath.last;
            _totalDistanceKm += (Geolocator.distanceBetween(lastPoint.latitude, lastPoint.longitude, newPoint.latitude, newPoint.longitude) / 1000);
            if (_lastAltitude != null && position.altitude > _lastAltitude!) {
              _elevationGain += (position.altitude - _lastAltitude!);
            }
          }
          _currentPath.add(newPoint);
          _lastAltitude = position.altitude;
        });
        _mapController.move(newPoint, _mapController.camera.zoom);
      }
    });
  }

  void _stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();
    final points = _currentPath.map((p) => RoutePoint(
      position: p, 
      timestamp: 0, 
      distance: 0, 
      altitude: 0
    )).toList();
    ref.read(activePathProvider.notifier).state = points;
    context.push('/post-run?distance=$_totalDistanceKm&time=$_secondsElapsed&elevation=$_elevationGain');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF23A2D9);
    final minutes = (_secondsElapsed / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(38.7223, -9.1393),
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.selfrival',
              ),
              PolylineLayer(
                polylines: [
                  if (_targetRoute != null)
                    Polyline(
                      points: _targetRoute!.path,
                      color: Colors.white.withValues(alpha: 0.3),
                      strokeWidth: 8.0,
                    ),
                  Polyline(
                    points: _currentPath,
                    color: primaryColor,
                    strokeWidth: 6.0,
                  ),
                ],
              ),
            ],
          ),

          // Header HUD (Glass)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_targetRoute?.name ?? "FREE RUN").toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                            const Text(
                              "MISSION IN PROGRESS",
                              style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Stats
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(label: 'TIME', value: '$minutes:$seconds', icon: Icons.timer_outlined),
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                            _StatItem(label: 'DISTANCE', value: _totalDistanceKm.toStringAsFixed(2), icon: Icons.directions_run_rounded),
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                            _StatItem(label: 'ALTITUDE', value: _elevationGain.toStringAsFixed(0), icon: Icons.landscape_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _StopBtn(onPressed: _stopRun),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ],
    );
  }
}

class _StopBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _StopBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: const CircleBorder(),
          elevation: 10,
          shadowColor: Colors.redAccent.withValues(alpha: 0.4),
        ),
        onPressed: onPressed,
        child: const Icon(Icons.stop_rounded, color: Colors.white, size: 36),
      ),
    );
  }
}
