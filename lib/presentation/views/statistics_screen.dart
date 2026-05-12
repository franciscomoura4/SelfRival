import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../data/models/route_model.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PERFORMANCE', style: TextStyle(letterSpacing: 2)),
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (routes) {
          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23A2D9).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_outlined, size: 48, color: Color(0xFF23A2D9)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ready for your first run?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Your stats will appear here.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final primaryRoute = routes.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: Color(0xFF23A2D9), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        primaryRoute.name.toUpperCase(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _PaceLineChart(route: primaryRoute),
                
                const SizedBox(height: 32),
                
                const Text(
                  'INSIGHTS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _ImpactCardSmall(
                        icon: Icons.terrain_rounded,
                        color: Colors.orange,
                        value: '${primaryRoute.elevationGain.toStringAsFixed(0)}m',
                        label: 'Elevation',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImpactCardSmall(
                        icon: Icons.speed_rounded,
                        color: Colors.green,
                        value: '${((primaryRoute.distance / primaryRoute.personalBestTime) * 3.6).toStringAsFixed(1)}',
                        label: 'Avg km/h',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                const Text(
                  'ROUTE MASTERS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final r = routes[index];
                    final min = (r.personalBestTime / 60).floor();
                    final sec = (r.personalBestTime % 60).toInt();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF23A2D9).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.route_rounded, color: Color(0xFF23A2D9), size: 20),
                        ),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: Text(
                          '${r.distance.toStringAsFixed(2)} km • PB $min:${sec.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImpactCardSmall extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _ImpactCardSmall({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PaceLineChart extends StatelessWidget {
  final RouteMaster route;

  const _PaceLineChart({required this.route});

  @override
  Widget build(BuildContext context) {
    // Generate simple pace spots from route points if available
    // For visualization, we take a subset of points
    List<FlSpot> spots = [];
    if (route.points.length > 1) {
      int step = (route.points.length / 10).clamp(1, 1000).toInt();
      for (int i = 0; i < route.points.length; i += step) {
        final p = route.points[i];
        if (p.timestamp > 0 && p.distance > 0) {
          // Pace in min/km
          double pace = (p.timestamp / (p.distance / 1000)) / 60;
          if (pace < 15 && pace > 2) { // Filter outliers
            spots.add(FlSpot(p.distance / 1000, pace));
          }
        }
      }
    }

    // Fallback spots if no point data is available
    if (spots.isEmpty) {
      spots = [
        const FlSpot(0, 5.0),
        FlSpot(route.distance * 0.5, 5.2),
        FlSpot(route.distance, 5.1),
      ];
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text('${value.toInt()}\'', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                reservedSize: 35,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('${value.toStringAsFixed(1)}k', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                reservedSize: 30,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF23A2D9),
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF23A2D9).withValues(alpha: 0.2),
                    const Color(0xFF23A2D9).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ImpactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
