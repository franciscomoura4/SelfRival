import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapController = MapController();

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

    if (trackingState.trackedPoints.isNotEmpty) {
      _mapController.move(trackingState.trackedPoints.last.position, 17.0);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(38.7223, -9.1393),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.selfrival',
                      ),
                      PolylineLayer(
                        polylines: [
                          if (targetRoute != null)
                            Polyline(
                              points: targetRoute.points.map((p) => p.position).toList(),
                              color: Colors.grey.withOpacity(0.5),
                              strokeWidth: 6.0,
                            ),
                          if (trackingState.trackedPoints.isNotEmpty)
                            Polyline(
                              points: trackingState.trackedPoints.map((p) => p.position).toList(),
                              color: const Color(0xFF23A2D9),
                              strokeWidth: 5.0,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          if (trackingState.trackedPoints.isNotEmpty)
                            Marker(
                              point: trackingState.trackedPoints.last.position,
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.blue, blurRadius: 10)],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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
                            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                            child: const Text('RACING GHOST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          if (trackingState.ghostTimeDelta != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: trackingState.ghostTimeDelta! <= 0 ? Colors.green : Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                trackingState.ghostTimeDelta! <= 0
                                    ? 'AHEAD ${trackingState.ghostTimeDelta!.abs().toInt()}s'
                                    : 'BEHIND ${trackingState.ghostTimeDelta!.abs().toInt()}s',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                          if (trackingState.isOffRoute)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('OFF ROUTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _StatView(label: 'TIME', value: _formatDuration(trackingState.elapsedTime))),
                          Expanded(child: _StatView(label: 'DISTANCE', value: (trackingState.totalDistance / 1000).toStringAsFixed(2))),
                          Expanded(child: _StatView(label: 'PACE', value: _formatPace(trackingState.currentPace).split(' ')[0])),
                        ],
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 80, width: 80,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 10,
                            shadowColor: Colors.redAccent.withOpacity(0.5),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Long press (hold) the button to stop the run!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onLongPress: () {
                            final finalState = trackingState;
                            ref.read(trackingProvider.notifier).stopTracking();
                            ref.read(activePathProvider.notifier).state = finalState.trackedPoints;
                            context.go('/post-run?distance=${finalState.totalDistance / 1000}&time=${finalState.elapsedTime.inSeconds}&elevation=${finalState.elevationGain}&isCompleted=${finalState.isRouteCompleted}');
                          },
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop_rounded, size: 32),
                              Text('HOLD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      ],
    );
  }
}