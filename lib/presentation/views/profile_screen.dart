import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/route_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final routesState = ref.watch(routeProvider);
    final routes = routesState.value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final initial = user?.name.isNotEmpty == true
        ? user!.name.substring(0, 1).toUpperCase()
        : 'U';

    // Stats derived from routes
    final totalRoutes = routes.length;
    final totalDistance = routes.fold(0.0, (sum, r) => sum + r.distance);
    final bestPace = routes.isEmpty
        ? null
        : routes
            .where((r) => r.distance > 0)
            .fold<double?>(null, (best, r) {
              final pace = r.personalBestTime / 60 / r.distance;
              return (best == null || pace < best) ? pace : best;
            });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // --- Avatar ---
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Name & Email ---
            Text(
              user?.name ?? 'Runner',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 32),

            // --- Stats row ---
            _StatsRow(
              totalRoutes: totalRoutes,
              totalDistance: totalDistance,
              bestPace: bestPace,
              isDark: isDark,
              colors: colors,
            ),
            const SizedBox(height: 32),

            // --- Sign Out ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text('You will be returned to the login screen.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(ctx).colorScheme.error,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authProvider.notifier).logout();
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalRoutes;
  final double totalDistance;
  final double? bestPace;
  final bool isDark;
  final ColorScheme colors;

  const _StatsRow({
    required this.totalRoutes,
    required this.totalDistance,
    required this.bestPace,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bestPaceLabel = bestPace == null
        ? '—'
        : '${bestPace!.floor()}:${((bestPace! % 1) * 60).round().toString().padLeft(2, '0')}';

    return Row(
      children: [
        _StatCard(
          value: '$totalRoutes',
          label: 'Routes',
          icon: Icons.route_rounded,
          isDark: isDark,
          colors: colors,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${totalDistance.toStringAsFixed(1)} km',
          label: 'Total Distance',
          icon: Icons.straighten_rounded,
          isDark: isDark,
          colors: colors,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: bestPaceLabel,
          label: 'Best Pace /km',
          icon: Icons.speed_rounded,
          isDark: isDark,
          colors: colors,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;
  final ColorScheme colors;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
