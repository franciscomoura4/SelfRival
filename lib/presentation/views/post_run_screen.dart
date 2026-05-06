import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../data/models/route_model.dart';

class PostRunScreen extends ConsumerStatefulWidget {
  final double distance;
  final int time;
  final double elevation;

  const PostRunScreen({super.key, this.distance = 0.0, this.time = 0, this.elevation = 0.0});

  @override
  ConsumerState<PostRunScreen> createState() => _PostRunScreenState();
}

class _PostRunScreenState extends ConsumerState<PostRunScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveNewCircuit(List<LatLng> path) {
    ref.read(routeProvider.notifier).saveNewRoute(_nameController.text, widget.distance, widget.time.toDouble(), widget.elevation, path);
    ref.read(targetRouteIdProvider.notifier).state = null; // Clear state
    context.go('/');
  }

  void _updatePB(String routeId) {
    ref.read(routeProvider.notifier).updatePersonalBest(routeId, widget.time.toDouble());
    ref.read(targetRouteIdProvider.notifier).state = null;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final path = ref.watch(activePathProvider);
    final targetRouteId = ref.watch(targetRouteIdProvider);
    final routes = ref.watch(routeProvider).value ?? [];

    RouteMaster? targetRoute;
    bool isNewPB = false;
    double timeDiff = 0.0;

    if (targetRouteId != null) {
      targetRoute = routes.firstWhere((r) => r.id == targetRouteId);
      timeDiff = widget.time - targetRoute.personalBestTime;
      isNewPB = timeDiff < 0;
    }

    final minutes = (widget.time / 60).floor().toString().padLeft(2, '0');
    final seconds = (widget.time % 60).toString().padLeft(2, '0');

    LatLngBounds? bounds;
    if (path.isNotEmpty) {
      double? minLat, maxLat, minLng, maxLng;
      for (var point in path) {
        if (minLat == null || point.latitude < minLat) minLat = point.latitude;
        if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
        if (minLng == null || point.longitude < minLng) minLng = point.longitude;
        if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
      }
      bounds = LatLngBounds(northeast: LatLng(maxLat!, maxLng!), southwest: LatLng(minLat!, minLng!));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Run Completed'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAP VISUALIZER
            Container(
              height: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF23A2D9), width: 2)), clipBehavior: Clip.antiAlias,
              child: path.isEmpty
                  ? const Center(child: Text("No GPS data recorded.", style: TextStyle(color: Colors.grey)))
                  : GoogleMap(
                initialCameraPosition: CameraPosition(target: path.first, zoom: 15), zoomControlsEnabled: false,
                polylines: {Polyline(polylineId: const PolylineId('summary'), points: path, color: const Color(0xFF23A2D9), width: 5)},
                onMapCreated: (controller) {
                  controller.setMapStyle('[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]');
                  if (bounds != null) Future.delayed(const Duration(milliseconds: 500), () => controller.animateCamera(CameraUpdate.newLatLngBounds(bounds!, 30)));
                },
              ),
            ),
            const SizedBox(height: 24),

            // STATS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [const Text('DISTANCE', style: TextStyle(color: Colors.grey)), Text('${widget.distance.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                    Column(children: [const Text('TIME', style: TextStyle(color: Colors.grey)), Text('$minutes:$seconds', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                    Column(children: [const Text('ELEV', style: TextStyle(color: Colors.grey)), Text('${widget.elevation.toStringAsFixed(0)} m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (targetRoute == null) ...[
              const Text('Save as New Circuit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Circuit Name', prefixIcon: Icon(Icons.edit_road))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF23A2D9), foregroundColor: Colors.white), onPressed: () => _saveNewCircuit(path), child: const Text('Save to Cloud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            ] else ...[
              const Text('Circuit Results', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Text('Target: ${targetRoute!.name}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 16),

              // PB COMPARISON BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isNewPB ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: isNewPB ? Colors.green : Colors.red)),
                child: Row(
                  children: [
                    Icon(isNewPB ? Icons.emoji_events : Icons.timer_off, color: isNewPB ? Colors.green : Colors.red, size: 32),
                    const SizedBox(width: 16),
                    Expanded(child: Text(
                      isNewPB ? 'NEW PERSONAL BEST!\nYou beat your time by ${timeDiff.abs().toInt()} seconds.' : 'Slower than PB.\nYou were ${timeDiff.toInt()} seconds behind.',
                      style: TextStyle(color: isNewPB ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (isNewPB)
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _updatePB(targetRoute!.id), child: const Text('Update Cloud PB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))
              else
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white), onPressed: () { ref.read(targetRouteIdProvider.notifier).state = null; context.go('/'); }, child: const Text('Save Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            ],

            SizedBox(width: double.infinity, height: 50, child: TextButton(onPressed: () { ref.read(targetRouteIdProvider.notifier).state = null; context.go('/'); }, child: const Text('Discard', style: TextStyle(color: Colors.grey)))),
          ],
        ),
      ),
    );
  }
}