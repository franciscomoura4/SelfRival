import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/route_viewmodel.dart';

class PostRunScreen extends ConsumerStatefulWidget {
  const PostRunScreen({super.key});

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

  void _saveRouteAndFinish() {
    // Call the Auto-Genesis logic in the ViewModel
    // Hardcoding the distance and time for this test (5.2km, 26m10s)
    ref.read(routeProvider.notifier).saveNewRoute(
      _nameController.text,
      5.2,
      (26 * 60) + 10,
    );

    // Go back to the dashboard
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Completed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.verified, size: 80, color: Color(0xFF23A2D9))),
            const SizedBox(height: 16),
            const Center(child: Text('Great job!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
            const SizedBox(height: 32),

            const Text('Run Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Distance', '5.2 km'),
                    const Divider(),
                    _buildSummaryRow('Time', '26:10'),
                    const Divider(),
                    _buildSummaryRow('Avg Pace', '5:02 /km'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text('Auto-Genesis Route Creation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Save this trajectory as a new Route Master to race against it later.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController, // Attached the controller here!
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Route Name',
                hintText: 'e.g., Morning Commute',
                prefixIcon: Icon(Icons.edit_road),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF23A2D9), foregroundColor: Colors.white),
                onPressed: _saveRouteAndFinish, // Trigger the save function!
                child: const Text('Save Route & Finish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Discard Route (Save Activity Only)', style: TextStyle(color: Colors.grey)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}