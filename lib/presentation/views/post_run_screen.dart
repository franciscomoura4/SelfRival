import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../data/models/route_model.dart';

class PostRunScreen extends ConsumerStatefulWidget {
  final double distance;
  final int time;
  final double elevation;
  final bool isCompleted;
  final int stepCount;

  const PostRunScreen({
    super.key,
    this.distance = 0.0,
    this.time = 0,
    this.elevation = 0.0,
    this.isCompleted = false,
    this.stepCount = 0,
  });

  @override
  ConsumerState<PostRunScreen> createState() => _PostRunScreenState();
}

class _PostRunScreenState extends ConsumerState<PostRunScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveFreeRun(List<RoutePoint> points) async {
    setState(() => _isSaving = true);
    await ref.read(routeProvider.notifier).saveFreeRun(
          _nameController.text,
          widget.distance,
          widget.time.toDouble(),
          widget.elevation,
          points,
          stepCount: widget.stepCount,
        );
    ref.read(targetRouteIdProvider.notifier).state = null;
    if (mounted) context.go('/');
  }

  Future<void> _saveGhostRun(
      String targetRouteId, List<RoutePoint> points) async {
    setState(() => _isSaving = true);
    final added = await ref.read(routeProvider.notifier).saveGhostRun(
          targetRouteId,
          widget.distance,
          widget.time.toDouble(),
          widget.elevation,
          points,
          stepCount: widget.stepCount,
        );
    ref.read(targetRouteIdProvider.notifier).state = null;
    if (!mounted) return;
    final routes = ref.read(routeProvider).value ?? [];
    final routeName = added
        ? routes.firstWhere((r) => r.id == targetRouteId,
                orElse: () => AppRoute(
                    id: '', name: 'Route', circuit: [], distance: 0,
                    elevationGain: 0, activities: []))
            .name
        : 'New Circuit';
    final message = added
        ? 'Activity added to "$routeName"'
        : 'Path diverged — saved as "$routeName"';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final rawPoints = ref.watch(activePathProvider);
    final latLngPath = rawPoints.map((p) => p.position).toList();

    final targetRouteId = ref.watch(targetRouteIdProvider);
    final routes = ref.watch(routeProvider).value ?? [];

    AppRoute? targetRoute;
    if (targetRouteId != null) {
      try {
        targetRoute = routes.firstWhere((r) => r.id == targetRouteId);
      } catch (_) {
        targetRoute = null;
      }
    }

    final minutes = (widget.time / 60).floor().toString().padLeft(2, '0');
    final seconds = (widget.time % 60).toString().padLeft(2, '0');

    LatLngBounds? bounds;
    if (latLngPath.length > 1) {
      bounds = LatLngBounds.fromPoints(latLngPath);
    }

    const primaryColor = Color(0xFF23A2D9);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Immersive Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D1B2A),
                    Colors.black,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SESSION SUMMARY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'DATA SYNCHRONIZED',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      _BlurActionCircle(
                        icon: Icons.close_rounded,
                        onPressed: () {
                          ref.read(targetRouteIdProvider.notifier).state = null;
                          context.go('/');
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map Preview
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: latLngPath.isEmpty
                              ? const Center(child: Text("No GPS data recorded.", style: TextStyle(color: Colors.white38)))
                              : FlutterMap(
                            options: MapOptions(
                              initialCameraFit: bounds != null
                                  ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48))
                                  : null,
                              initialCenter: latLngPath.isNotEmpty ? latLngPath.first : const LatLng(0, 0),
                              initialZoom: 2.0,
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
                                    points: latLngPath,
                                    color: primaryColor,
                                    strokeWidth: 6.0,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Stats Grid (Glass)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                  _SummaryStat(label: 'DISTANCE', value: widget.distance.toStringAsFixed(2), unit: 'KM', icon: Icons.straighten_rounded),
                                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                  _SummaryStat(label: 'TIME', value: '$minutes:$seconds', unit: '', icon: Icons.timer_outlined),
                                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                  _SummaryStat(label: 'ALTITUDE', value: widget.elevation.toStringAsFixed(0), unit: 'M', icon: Icons.landscape_rounded),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        if (targetRoute == null) ...[
                          const Row(
                            children: [
                              Icon(Icons.add_location_alt_rounded, color: primaryColor, size: 18),
                              SizedBox(width: 12),
                              Text(
                                'ARCHIVE NEW CIRCUIT',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _nameController,
                            label: 'CIRCUIT NAME',
                            icon: Icons.edit_road_rounded,
                          ),
                          const SizedBox(height: 32),
                          _ActionBtn(
                            label: 'SAVE TO CLOUD',
                            color: primaryColor,
                            icon: Icons.cloud_upload_rounded,
                            onPressed: _isSaving ? () {} : () => _saveFreeRun(rawPoints),
                          ),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.insights_rounded, color: primaryColor, size: 18),
                              SizedBox(width: 12),
                              Text(
                                'GHOST RUN COMPLETE',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _GhostRunCard(
                            routeName: targetRoute.name,
                            isCompleted: widget.isCompleted,
                          ),
                          const SizedBox(height: 32),
                          _ActionBtn(
                            label: _isSaving ? 'SAVING...' : 'SAVE ACTIVITY',
                            color: primaryColor,
                            icon: Icons.save_rounded,
                            onPressed: _isSaving
                                ? () {}
                                : () => _saveGhostRun(targetRoute!.id, rawPoints),
                          ),
                        ],

                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              ref.read(targetRouteIdProvider.notifier).state = null;
                              context.go('/');
                            },
                            child: const Text(
                              'DISCARD ACTIVITY',
                              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        prefixIcon: Icon(icon, color: const Color(0xFF23A2D9).withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF23A2D9), width: 2)),
      ),
    );
  }
}

class _GhostRunCard extends StatelessWidget {
  final String routeName;
  final bool isCompleted;

  const _GhostRunCard({required this.routeName, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? const Color(0xFF23A2D9) : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.psychology_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'GHOST RUN COMPLETE' : 'INCOMPLETE RUN',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  routeName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted
                      ? 'Save this activity. Similarity will be checked against the route — if ≥ 70% match, it\'s added to the route; otherwise a new route is created.'
                      : 'You stopped early. The activity will still be evaluated for route similarity.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _SummaryStat({required this.label, required this.value, required this.unit, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 2),
                child: Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ],
    );
  }
}

class _BlurActionCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _BlurActionCircle({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 20),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
