import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Consistency: "River Loop"',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compare your pace across multiple attempts on the exact same trajectory.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Placeholder for fl_chart (Lab Requirement: Custom Drawing)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF23A2D9), width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Color(0xFF23A2D9)),
                  SizedBox(height: 16),
                  Text(
                    'fl_chart Visualization Area\n(Pace vs Distance Graph)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'External Factors (REST API)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Placeholder for REST API requirement
            Card(
              color: Colors.blueGrey[900],
              child: const ListTile(
                leading: Icon(Icons.cloud, color: Colors.lightBlueAccent, size: 36),
                title: Text('Weather Impact Analysis'),
                subtitle: Text('Data fetched via OpenWeatherMap GET Request. You run 3% slower when humidity is > 80%.'),
              ),
            ),
            Card(
              color: Colors.blueGrey[900],
              child: const ListTile(
                leading: Icon(Icons.terrain, color: Colors.brown, size: 36),
                title: Text('Altimetry Analysis'),
                subtitle: Text('Data fetched via Google Elevation API. Most time lost on 4% inclines.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}