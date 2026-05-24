import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/route_viewmodel.dart';
import '../viewmodels/sort_viewmodel.dart';
import '../../data/models/route_model.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routeProvider);
    final sortOption = ref.watch(sortOptionProvider);
    const primaryColor = Color(0xFF23A2D9);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Immersive Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1B2A), Colors.black, Colors.black],
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
                            'PERFORMANCE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'ATHLETE INSIGHTS',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _SortDropdown(
                            currentOption: sortOption,
                            onChanged: (val) => ref.read(sortOptionProvider.notifier).state = val!,
                          ),
                          const SizedBox(width: 12),
                          _BlurActionCircle(
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: routesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
                    error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
                    data: (routes) {
                      if (routes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.analytics_outlined, size: 48, color: primaryColor),
                              ),
                              const SizedBox(height: 24),
                              const Text('NO MISSIONS RECORDED', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ],
                          ),
                        );
                      }

                      // Apply sorting
                      final sortedRoutes = List<AppRoute>.from(routes);
                      if (sortOption == SortOption.distance) {
                        sortedRoutes.sort((a, b) => b.distance.compareTo(a.distance));
                      } else {
                        sortedRoutes.sort((a, b) {
                          final timeA = a.personalBestTime;
                          final timeB = b.personalBestTime;
                          if (timeA == 0) return 1;
                          if (timeB == 0) return -1;
                          return timeA.compareTo(timeB);
                        });
                      }

                      final primaryRoute = sortedRoutes.first;
                      final bestActivity = primaryRoute.activities.isNotEmpty
                          ? primaryRoute.activities
                              .reduce((a, b) => a.time < b.time ? a : b)
                          : null;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel(label: 'ARCHIVE LEADER', icon: Icons.insights_rounded),
                            const SizedBox(height: 16),
                            
                            // Glass Chart
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        primaryRoute.name.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 200,
                                        child: PaceLineChart(
                                          points: bestActivity?.points ?? primaryRoute.circuit,
                                          distance: bestActivity?.distance ?? primaryRoute.distance,
                                          isGlass: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            const _SectionLabel(label: 'VITAL INSIGHTS', icon: Icons.bolt_rounded),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _GlassStatCard(
                                    icon: Icons.terrain_rounded,
                                    color: Colors.orangeAccent,
                                    value: '${(bestActivity?.elevationGain ?? primaryRoute.elevationGain).toStringAsFixed(0)}M',
                                    label: 'ELEVATION',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _GlassStatCard(
                                    icon: Icons.speed_rounded,
                                    color: const Color(0xFF00E676),
                                    value: bestActivity != null
                                        ? bestActivity.avgSpeed.toStringAsFixed(1)
                                        : '0.0',
                                    label: 'AVG KM/H',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),
                            const _SectionLabel(label: 'ROUTE MASTERY', icon: Icons.route_rounded),
                            const SizedBox(height: 16),
                            
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedRoutes.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final r = sortedRoutes[index];
                                final min = (r.personalBestTime / 60).floor();
                                final sec = (r.personalBestTime % 60).toInt();
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.map_rounded, color: primaryColor, size: 20),
                                    ),
                                    title: Text(r.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                                    subtitle: Text('${r.distance.toStringAsFixed(2)} KM • PB $min:${sec.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w700)),
                                    onTap: () => context.push('/route-details/${r.id}'),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
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

class _SortDropdown extends StatelessWidget {
  final SortOption currentOption;
  final ValueChanged<SortOption?> onChanged;

  const _SortDropdown({required this.currentOption, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          value: currentOption,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(Icons.sort_rounded, color: Colors.white54, size: 18),
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
          items: const [
            DropdownMenuItem(value: SortOption.distance, child: Text('DISTANCE')),
            DropdownMenuItem(value: SortOption.time, child: Text('TIME')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _GlassStatCard({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ],
      ),
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

class PaceLineChart extends StatelessWidget {
  final List<RoutePoint> points;
  final double distance;
  final bool isGlass;

  const PaceLineChart(
      {super.key,
      required this.points,
      required this.distance,
      this.isGlass = false});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];

    if (points.length > 1) {
      int step = (points.length / 10).clamp(1, 1000).toInt();
      RoutePoint? prevPoint;

      for (int i = 0; i < points.length; i += step) {
        final p = points[i];
        if (prevPoint != null) {
          double deltaDistKm = (p.distance - prevPoint.distance) / 1000;
          double deltaSec = p.timestamp - prevPoint.timestamp;

          if (deltaDistKm > 0.01 && deltaSec > 0) {
            double segmentPace = (deltaSec / deltaDistKm) / 60;
            if (segmentPace < 15 && segmentPace > 2) {
              spots.add(FlSpot(p.distance / 1000, segmentPace));
            }
          }
        }
        prevPoint = p;
      }
    }

    if (spots.isEmpty) {
      spots = [const FlSpot(0, 5.0), FlSpot(distance * 0.5, 5.2), FlSpot(distance, 5.1)];
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text('${value.toInt()}\'', style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold)),
              ),
              reservedSize: 24,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${value.toStringAsFixed(1)}K', style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold)),
              ),
              reservedSize: 24,
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
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF23A2D9).withValues(alpha: 0.2), const Color(0xFF23A2D9).withValues(alpha: 0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
