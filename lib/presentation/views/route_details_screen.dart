import 'dart:ui';
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
    const primaryColor = Color(0xFF23A2D9);

    return Scaffold(
      backgroundColor: Colors.black,
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, stack) => _DetailsErrorView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.refresh(routeProvider),
        ),
        data: (routes) {
          AppRoute? route;
          try {
            route = routes.firstWhere((r) => r.id == routeId);
          } catch (_) {
            return const Center(child: Text('Route not found', style: TextStyle(color: Colors.white)));
          }

          LatLngBounds? bounds;
          if (route.circuit.isNotEmpty) {
            bounds = LatLngBounds.fromPoints(route.circuit.map((e) => e.position).toList());
          }

          return Stack(
            children: [
              // Immersive Map Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.85, 1.0],
                    ),
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: bounds != null
                          ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(64))
                          : null,
                      initialCenter: route.circuit.isNotEmpty
                          ? route.circuit.first.position
                          : const LatLng(0, 0),
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
                            points: route.path,
                            color: primaryColor,
                            strokeWidth: 6.0,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Glass Back & Delete Actions
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BlurActionCircle(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => context.pop(),
                        ),
                        _BlurActionCircle(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          onPressed: () => _confirmDeletion(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Panel
              Positioned(
                top: MediaQuery.of(context).size.height * 0.38,
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TARGET: BEAT PERSONAL BEST',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Glass Stat Grid
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _DetailStat(label: 'DISTANCE', value: route.distance.toStringAsFixed(2), unit: 'KM', icon: Icons.straighten_rounded),
                                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                _DetailStat(label: 'PB TIME', value: _formatTime(route.personalBestTime), unit: '', icon: Icons.emoji_events_rounded),
                                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                _DetailStat(label: 'GAIN', value: route.elevationGain.toStringAsFixed(0), unit: 'M', icon: Icons.landscape_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Row(
                        children: [
                          Icon(Icons.analytics_rounded, color: Colors.white54, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'PACE ARCHITECTURE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white54,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: PaceLineChart(points: route.circuit, distance: route.distance),
                      ),

                      if (route.activities.isNotEmpty) ...[  
                        const SizedBox(height: 40),
                        const Row(
                          children: [
                            Icon(Icons.directions_run_rounded, color: Colors.white54, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'ACTIVITIES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: route.activities.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final act = route!.activities[index];
                            final isBest = act.time == route.personalBestTime;
                            final min = (act.time / 60).floor().toString().padLeft(2, '0');
                            final sec = (act.time % 60).toInt().toString().padLeft(2, '0');
                            final dateStr =
                                '${act.date.day.toString().padLeft(2, '0')}/${act.date.month.toString().padLeft(2, '0')}/${act.date.year}';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isBest
                                    ? primaryColor.withValues(alpha: 0.07)
                                    : Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isBest
                                      ? primaryColor.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isBest
                                          ? primaryColor.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isBest
                                          ? Icons.emoji_events_rounded
                                          : Icons.directions_run_rounded,
                                      color: isBest ? primaryColor : Colors.white38,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: isBest ? Colors.white : Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            _ActivityChip(label: '$min:$sec', icon: Icons.timer_outlined),
                                            const SizedBox(width: 10),
                                            _ActivityChip(
                                              label: '${act.distance.toStringAsFixed(2)} km',
                                              icon: Icons.straighten_rounded,
                                            ),
                                            const SizedBox(width: 10),
                                            _ActivityChip(
                                              label: '${act.avgSpeed.toStringAsFixed(1)} km/h',
                                              icon: Icons.speed_rounded,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isBest)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'PB',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Island
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
                        Colors.black,
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            label: 'RACE GHOST',
                            color: Colors.white.withValues(alpha: 0.1),
                            textColor: Colors.white,
                            icon: Icons.psychology_rounded,
                            onPressed: () => context.push('/run?routeId=$routeId'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionBtn(
                            label: 'START RUN',
                            color: primaryColor,
                            textColor: Colors.white,
                            icon: Icons.play_arrow_rounded,
                            onPressed: () => context.push('/run'),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('DELETE ROUTE?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
          content: const Text(
            'This action cannot be undone and your performance history will be lost.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: () {
                ref.read(routeProvider.notifier).deleteRoute(routeId);
                Navigator.pop(context);
                context.go('/');
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _DetailsErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1B2A), Colors.black],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 16),
                        const Text('MISSION FAILED',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        Text(message.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('ABORT', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('RETRY', style: TextStyle(fontWeight: FontWeight.w900)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF23A2D9),
                                backgroundColor: const Color(0xFF23A2D9).withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
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
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _DetailStat({required this.label, required this.value, required this.unit, required this.icon});

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
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ],
    );
  }
}

class _BlurActionCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _BlurActionCircle({required this.icon, required this.onPressed, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 20),
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
  final Color textColor;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActivityChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.white38),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}