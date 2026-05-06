import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActiveRunScreen extends ConsumerWidget {
  final String? routeId;

  const ActiveRunScreen({super.key, this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRacingRoute = routeId != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // TOP HALF: Map Area (Lab Requirement: Visualization/Device Capability)
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Text(
                        'Google Maps / GPS Polyline Area\n(geolocator & google_maps_flutter)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      onPressed: () => context.pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  if (isRacingRoute)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'RACING: Route PB',
                          style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // BOTTOM HALF: Telemetry & Controls
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Pacing Coach (Core Innovation feature)
                    if (isRacingRoute)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Pacing Coach: -0:05 (Ahead of PB!)',
                              style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatView(label: 'Time', value: '12:34'),
                        _StatView(label: 'Distance', value: '2.4 km'),
                        _StatView(label: 'Pace', value: '5:14 /km'),
                      ],
                    ),
                    
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: FloatingActionButton(
                        backgroundColor: Colors.redAccent,
                        shape: const CircleBorder(),
                        onPressed: () {
                          // Stop run, save activity, navigate to Post-Run screen
                          context.go('/post-run');
                        },
                        child: const Icon(Icons.stop, size: 40, color: Colors.white),
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
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}