import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../data/models/route_model.dart';
import 'statistics_screen.dart';

class RouteDetailsScreen extends ConsumerWidget {
  final String routeId;

  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PREPARE TO RUN', style: TextStyle(letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDeletion(context, ref),
          ),
        ],
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (routes) {
          RouteMaster? route;
          try {
            route = routes.firstWhere((r) => r.id == routeId);
          } catch (_) {
            return const Center(child: Text('Route not found'));
          }

          LatLngBounds? bounds;
          if (route.points.isNotEmpty) {
            bounds = LatLngBounds.fromPoints(route.points.map((e) => e.position).toList());
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name.toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCameraFit: bounds != null
                                ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32))
                                : null,
                            initialCenter: route.points.isNotEmpty
                                ? route.points.first.position
                                : const LatLng(38.7223, -9.1393),
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.selfrival',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: route.path,
                                  color: const Color(0xFF23A2D9),
                                  strokeWidth: 6.0,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DetailStat(label: 'DISTANCE', value: '${route.distance.toStringAsFixed(2)} km'),
                          _DetailStat(label: 'PB TIME', value: _formatTime(route.personalBestTime)),
                          _DetailStat(label: 'ELEVATION', value: '${route.elevationGain.toStringAsFixed(0)} m'),
                        ],
                      ),

                      const SizedBox(height: 32),

                      const Text('PACE ANALYSIS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      SizedBox(height: 200, child: PaceLineChart(route: route)),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => context.push('/run?routeId=$routeId'),
                        child: const Text('RACE GHOST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF23A2D9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => context.push('/run'),
                        child: const Text('FREE RUN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).toInt();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _confirmDeletion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route?'),
        content: const Text('This action cannot be undone and your PB data will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(routeProvider.notifier).deleteRoute(routeId);
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}