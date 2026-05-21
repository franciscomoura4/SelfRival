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

  const PostRunScreen({
    super.key,
    this.distance = 0.0,
    this.time = 0,
    this.elevation = 0.0,
    this.isCompleted = false,
  });

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

  void _saveNewCircuit(List<RoutePoint> points) {
    ref.read(routeProvider.notifier).saveNewRoute(_nameController.text, widget.distance, widget.time.toDouble(), widget.elevation, points);
    ref.read(targetRouteIdProvider.notifier).state = null;
    context.go('/');
  }

  void _updatePB(String routeId) {
    ref.read(routeProvider.notifier).updatePersonalBest(routeId, widget.time.toDouble());
    ref.read(targetRouteIdProvider.notifier).state = null;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final rawPoints = ref.watch(activePathProvider);
    final latLngPath = rawPoints.map((p) => p.position).toList();

    final targetRouteId = ref.watch(targetRouteIdProvider);
    final routes = ref.watch(routeProvider).value ?? [];

    RouteMaster? targetRoute;
    bool isNewPB = false;
    double timeDiff = 0.0;

    if (targetRouteId != null) {
      try {
        targetRoute = routes.firstWhere((r) => r.id == targetRouteId);
        timeDiff = widget.time - targetRoute.personalBestTime;
        isNewPB = timeDiff < 0;
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
                              initialCenter: latLngPath.isNotEmpty ? latLngPath.first : const LatLng(38.7223, -9.1393),
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
                                  _SummaryStat(label: 'DISTANCE', value: '${widget.distance.toStringAsFixed(2)}', unit: 'KM', icon: Icons.straighten_rounded),
                                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                  _SummaryStat(label: 'TIME', value: '$minutes:$seconds', unit: '', icon: Icons.timer_outlined),
                                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                  _SummaryStat(label: 'ALTITUDE', value: '${widget.elevation.toStringAsFixed(0)}', unit: 'M', icon: Icons.landscape_rounded),
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
                            onPressed: () => _saveNewCircuit(rawPoints),
                          ),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.insights_rounded, color: primaryColor, size: 18),
                              SizedBox(width: 12),
                              Text(
                                'PERFORMANCE ANALYSIS',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _PerformanceResultCard(
                            isCompleted: widget.isCompleted,
                            isNewPB: isNewPB,
                            timeDiff: timeDiff,
                            routeName: targetRoute.name,
                          ),
                          const SizedBox(height: 32),
                          if (isNewPB && widget.isCompleted)
                            _ActionBtn(
                              label: 'UPDATE CLOUD PB',
                              color: const Color(0xFF4CAF50),
                              icon: Icons.auto_awesome_rounded,
                              onPressed: () => _updatePB(targetRoute!.id),
                            )
                          else
                            _ActionBtn(
                              label: 'FINISH SESSION',
                              color: Colors.white.withValues(alpha: 0.1),
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: () {
                                ref.read(targetRouteIdProvider.notifier).state = null;
                                context.go('/');
                              },
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

class _PerformanceResultCard extends StatelessWidget {
  final bool isCompleted;
  final bool isNewPB;
  final double timeDiff;
  final String routeName;

  const _PerformanceResultCard({
    required this.isCompleted,
    required this.isNewPB,
    required this.timeDiff,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = !isCompleted ? Colors.orangeAccent : (isNewPB ? const Color(0xFF00E676) : const Color(0xFFFF1744));
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: mainColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(!isCompleted ? Icons.warning_amber_rounded : (isNewPB ? Icons.emoji_events_rounded : Icons.timer_off_rounded), color: mainColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !isCompleted ? 'INCOMPLETE' : (isNewPB ? 'NEW PERSONAL BEST' : 'MISSION SLOWER'),
                      style: TextStyle(color: mainColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    Text(
                      routeName.toUpperCase(),
                      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            !isCompleted
                ? 'Checkpoints missing. You must cross the official finish line to update your PB history.'
                : (isNewPB
                ? 'Shattered! You beat your target by ${timeDiff.abs().toStringAsFixed(1)} seconds. Outstanding intensity.'
                : 'Behind! You were ${timeDiff.toStringAsFixed(1)} seconds off the target. Maintain focus next session.'),
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
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
