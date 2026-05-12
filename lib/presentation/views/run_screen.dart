import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../data/models/route_model.dart';

class RunScreen extends ConsumerStatefulWidget {
  final String? routeId; // If this is passed, we are racing a PB!
  const RunScreen({super.key, this.routeId});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  final List<LatLng> _currentPath = [];
  double _totalDistanceKm = 0.0;
  double _elevationGain = 0.0; //ALTTITUDE TRACKER
  double? _lastAltitude;
  int _secondsElapsed = 0;
  Timer? _timer;

  RouteMaster? _targetRoute;

  @override
  void initState() {
    super.initState();
    //app know if we are racing a ghost!
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
      setState(() => _secondsElapsed++);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);

      setState(() {
        if (_currentPath.isNotEmpty) {
          // Distance calc
          final lastPoint = _currentPath.last;
          _totalDistanceKm += (Geolocator.distanceBetween(lastPoint.latitude, lastPoint.longitude, newPoint.latitude, newPoint.longitude) / 1000);

          // Elevation calc (only add positive gains like Strava)
          if (_lastAltitude != null && position.altitude > _lastAltitude!) {
            _elevationGain += (position.altitude - _lastAltitude!);
          }
        }
        _currentPath.add(newPoint);
        _lastAltitude = position.altitude;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
    });
  }

  void _stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();
    ref.read(activePathProvider.notifier).state = _currentPath;
    // Push stats to the post-run screen!
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
    final minutes = (_secondsElapsed / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    // Polylines: Blue for the target ghost route (if it exists), Red for where YOU actually ran!
    Set<Polyline> polylines = {
      Polyline(polylineId: const PolylineId('active'), points: _currentPath, color: Colors.redAccent, width: 6, zIndex: 2),
    };
    if (_targetRoute != null) {
      polylines.add(Polyline(polylineId: const PolylineId('ghost'), points: _targetRoute!.path, color: Colors.blue.withOpacity(0.5), width: 8, zIndex: 1));
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(38.7223, -9.1393), zoom: 17.0),
            myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: false,
            polylines: polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle('[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]');
            },
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_targetRoute != null) ...[
                      Text('Racing Ghost: ${_targetRoute!.name}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [const Text('TIME', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), Text('$minutes:$seconds', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))]),
                        Column(children: [const Text('DISTANCE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), Text('${_totalDistanceKm.toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))]),
                        Column(children: [const Text('ELEV', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), Text('${_elevationGain.toStringAsFixed(0)} m', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _stopRun, child: const Text('STOP RUN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)))),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}