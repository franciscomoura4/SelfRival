import 'dart:ui';
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

class _ActiveRunScreenState extends ConsumerState<ActiveRunScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isFollowing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routes = ref.read(routeProvider).value ?? [];
      AppRoute? targetRoute;
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

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final isRacingRoute = widget.routeId != null;
    final routes = ref.watch(routeProvider).value ?? [];

    AppRoute? targetRoute;
    try {
      targetRoute = isRacingRoute ? routes.firstWhere((r) => r.id == widget.routeId) : null;
    } catch (_) {
      targetRoute = null;
    }

    ref.listen(trackingProvider, (previous, next) {
      if (_isFollowing && next.trackedPoints.isNotEmpty) {
        final double targetZoom = (previous?.trackedPoints.isEmpty ?? true) ? 17.0 : _mapController.camera.zoom;
        _animatedMapMove(next.trackedPoints.last.position, targetZoom);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full Screen Map Background
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(38.7223, -9.1393),
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _isFollowing = false);
                }
              },
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
                      points: targetRoute.circuit.map((p) => p.position).toList(),
                      color: Colors.white.withValues(alpha: 0.2),
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
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF23A2D9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF23A2D9).withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Header Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _CockpitHeader(
                state: trackingState,
                targetRoute: targetRoute,
                onClose: () {
                  ref.read(trackingProvider.notifier).stopTracking();
                  context.pop();
                },
              ),
            ),
          ),

          // Bottom Stats and Controls Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location Button Floating above Stats
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _BlurActionCircle(
                        icon: Icons.my_location_rounded,
                        color: _isFollowing ? const Color(0xFF23A2D9) : Colors.white,
                        onPressed: () {
                          setState(() => _isFollowing = true);
                          if (trackingState.trackedPoints.isNotEmpty) {
                            _animatedMapMove(trackingState.trackedPoints.last.position, 18.0);
                          }
                        },
                      ),
                    ),
                  ),

                  // Glass Stat Panel
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (trackingState.isAutoPaused)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.amber.withValues(
                                            alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          Icons.pause_circle_outline_rounded,
                                          color: Colors.amber,
                                          size: 12),
                                      SizedBox(width: 5),
                                      Text('AUTO PAUSED',
                                          style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatView(
                                    label: 'TIME',
                                    value: _formatDuration(
                                        trackingState.elapsedTime),
                                    icon: Icons.timer_outlined,
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.1)),
                                Expanded(
                                  child: _StatView(
                                    label: 'DISTANCE',
                                    value: (trackingState.totalDistance / 1000)
                                        .toStringAsFixed(2),
                                    icon: Icons.directions_run_rounded,
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.1)),
                                Expanded(
                                  child: _StatView(
                                    label: 'PACE',
                                    value: _formatPace(trackingState.currentPace)
                                        .split(' ')[0],
                                    icon: Icons.speed_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_walk_rounded,
                                    size: 11, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text(
                                  trackingState.cadence > 0
                                      ? '${trackingState.cadence.round()} spm  ·  ${trackingState.stepCount} steps'
                                      : '--  ·  ${trackingState.stepCount} steps',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stop Button
                  _StopButton(
                    onLongPress: () {
                      final finalState = trackingState;
                      ref.read(trackingProvider.notifier).stopTracking();
                      ref.read(activePathProvider.notifier).state = finalState.trackedPoints;
                      context.go('/post-run?distance=${finalState.totalDistance / 1000}&time=${finalState.elapsedTime.inSeconds}&elevation=${finalState.elevationGain}&isCompleted=${finalState.isRouteCompleted}&stepCount=${finalState.stepCount}');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _CockpitHeader extends StatelessWidget {
  final TrackingState state;
  final AppRoute? targetRoute;
  final VoidCallback onClose;

  const _CockpitHeader({
    required this.state,
    required this.targetRoute,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isAhead = (state.ghostTimeDelta ?? 0) <= 0;
    final isOffRoute = state.isOffRoute;
    final isRacing = targetRoute != null;

    final Color statusColor = isOffRoute
        ? Colors.orangeAccent
        : (isAhead ? const Color(0xFF00E676) : const Color(0xFFFF1744));

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Close Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                    ),
                  ),
                ),
                
                // Vertical Divider
                Container(width: 1, color: Colors.white.withValues(alpha: 0.1)),
                
                // Main Content Area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              (isRacing ? targetRoute!.name : "FREE RUN").toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (isRacing) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  isOffRoute ? "OFF ROUTE" : (isAhead ? "AHEAD" : "BEHIND"),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isRacing)
                              Text(
                                state.ghostTimeDelta != null
                                    ? "${state.ghostTimeDelta!.abs().toStringAsFixed(1)}s"
                                    : "--",
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            if (!isRacing)
                              const Text(
                                "RECORDING",
                                style: TextStyle(
                                  color: Color(0xFF23A2D9),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            if (state.coachMessage != null)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    state.coachMessage!.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatView extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatView({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 16),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _BlurActionCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _BlurActionCircle({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 24),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onLongPress;

  const _StopButton({required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hold to finish your session'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        height: 72,
        width: 72,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 4,
            )
          ],
        ),
        child: const Icon(Icons.stop_rounded, color: Colors.white, size: 36),
      ),
    );
  }
}
