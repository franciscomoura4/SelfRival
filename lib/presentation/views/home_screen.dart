import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/route_viewmodel.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetching mock data directly for now.
    final routes = ref.watch(routeProvider);
    final user = MockRepository.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SelfRival Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () {
              // Trigger logout. The router will automatically detect this
              // state change and kick the user back to /login.
              ref.read(authProvider.notifier).logout();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF23A2D9),
              child: Text(
                  user.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Route Masters',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a route to race against your Personal Best, or start a Free Run to generate a new route.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Route List
            Expanded(
              child: ListView.builder(
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  // Convert seconds to mm:ss format
                  final minutes = (route.personalBestTime / 60).floor();
                  final seconds = (route.personalBestTime % 60).toInt();

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF23A2D9),
                        child: Icon(Icons.map, color: Colors.white),
                      ),
                      title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('PB: $minutes:${seconds.toString().padLeft(2, '0')} • ${route.distance} km'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Navigate to Active Run and pass the routeId
                          context.push('/run?routeId=${route.id}');
                        },
                        child: const Text('RACE'),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Free Run Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_run),
                label: const Text('Start Free Run (Auto-Genesis)', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23A2D9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Navigate to Active Run with NO routeId (Free Tracking)
                  context.push('/run');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}