import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/tracking_service.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../data/models/route_model.dart';

class ActiveRunScreen extends ConsumerStatefulWidget {
  final String? routeId;

  const ActiveRunScreen({super.key, this.routeId});

  @override
  ConsumerState<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends ConsumerState<ActiveRunScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routes = ref.read(routeProvider).value ?? [];
      RouteMaster? targetRoute;
      try {
        targetRoute = widget.routeId != null 
            ? routes.firstWhere((r) => r.id == widget.routeId)
            : null;
      } catch (_) {
        targetRoute = null;
      }
      
      if (widget.routeId != null) {
        ref.read(targetRouteIdProvider.notifier).state = widget.routeId;
      }
      
      ref.read(trackingProvider.notifier).startTracking(targetRoute: targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final isRacingRoute = widget.routeId != null;
    final routes = ref.watch(routeProvider).value ?? [];
    
    RouteMaster? targetRoute;
    try {
      targetRoute = isRacingRoute ? routes.firstWhere((r) => r.id == widget.routeId) : null;
    } catch (_) {
      targetRoute = null;
    }

    // Auto-center and zoom map on current position
    if (trackingState.trackedPoints.isNotEmpty && _mapController != null) {
      final currentPos = trackingState.trackedPoints.last.position;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPos,
            zoom: 17.0,
            tilt: 45.0,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // TOP HALF: Map Area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(target: LatLng(38.7223, -9.1393), zoom: 15),
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    polylines: {
                      if (targetRoute != null)
                        Polyline(
                          polylineId: const PolylineId('target_route'),
                          points: targetRoute.points.map((p) => p.position).toList(),
                          color: Colors.grey.withValues(alpha: 0.5),
                          width: 6,
                        ),
                      Polyline(
                        polylineId: const PolylineId('current_run'),
                        points: trackingState.trackedPoints.map((p) => p.position).toList(),
                        color: const Color(0xFF23A2D9),
                        width: 5,
                      ),
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                      if (isDarkMode) {
                        _mapController?.setMapStyle(_darkMapStyle);
                      } else {
                        _mapController?.setMapStyle(null);
                      }
                    },
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      onPressed: () {
                         ref.read(trackingProvider.notifier).stopTracking();
                         context.pop();
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  if (isRacingRoute)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ROUTE MODE',
                              style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (trackingState.isOffRoute)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'OFF ROUTE',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // BOTTOM HALF: Telemetry & Controls
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatView(
                              label: 'TIME', 
                              value: _formatDuration(trackingState.elapsedTime)
                            ),
                          ),
                          Expanded(
                            child: _StatView(
                              label: 'DISTANCE', 
                              value: '${(trackingState.totalDistance / 1000).toStringAsFixed(2)}'
                            ),
                          ),
                          Expanded(
                            child: _StatView(
                              label: 'PACE', 
                              value: _formatPace(trackingState.currentPace).split(' ')[0]
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Center(
                      child: GestureDetector(
                        onLongPress: () {
                          final finalState = trackingState;
                          ref.read(trackingProvider.notifier).stopTracking();
                          ref.read(activePathProvider.notifier).state = finalState.trackedPoints.map((p) => p.position).toList();
                          context.go('/post-run?distance=${finalState.totalDistance / 1000}&time=${finalState.elapsedTime.inSeconds}&elevation=${finalState.elevationGain}&isCompleted=${finalState.isRouteCompleted}');
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop_rounded, size: 32, color: Colors.white),
                              Text('HOLD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatPace(double pace) {
    if (pace == 0 || pace.isInfinite) return "-:--";
    int minutes = (pace / 60).floor();
    int seconds = (pace % 60).round();
    return "$minutes:${seconds.toString().padLeft(2, '0')} /km";
  }

  final String _darkMapStyle = '''
  [
    {"elementType": "geometry","stylers": [{"color": "#212121"}]},
    {"elementType": "labels.icon","stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},
    {"elementType": "labels.text.stroke","stylers": [{"color": "#212121"}]},
    {"featureType": "administrative","elementType": "geometry","stylers": [{"color": "#757575"}]},
    {"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2c2c2c"}]},
    {"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#8a8a8a"}]},
    {"featureType": "water","elementType": "geometry","stylers": [{"color": "#000000"}]}
  ]
  ''';
}

class _StatView extends StatelessWidget {
  final String label;
  final String value;

  const _StatView({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value, 
          style: TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: Theme.of(context).colorScheme.onSurface,
          )
        ),
        const SizedBox(height: 4),
        Text(
          label, 
          style: TextStyle(
            color: Colors.grey[500], 
            fontSize: 10, 
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          )
        ),
      ],
    );
  }
}
