import 'dart:ui';
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
    const primaryColor = Color(0xFF23A2D9);

    final initial = user?.name.isNotEmpty == true
        ? user!.name.substring(0, 1).toUpperCase()
        : 'U';

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
                            'USER COCKPIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'IDENTITY VERIFIED',
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
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // --- Avatar Cockpit ---
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 8),
                              ),
                            ),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          (user?.name ?? 'ATHLETE').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email.toUpperCase() ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // --- Stats Island (Glass) ---
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
                                children: [
                                  _ProfileStat(label: 'ROUTES', value: '$totalRoutes', icon: Icons.route_rounded),
                                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                  _ProfileStat(label: 'TOTAL KM', value: totalDistance.toStringAsFixed(1), icon: Icons.straighten_rounded),
                                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                                  _ProfileStat(
                                    label: 'BEST PACE', 
                                    value: bestPace == null ? '--' : '${bestPace.floor()}:${((bestPace % 1) * 60).round().toString().padLeft(2, '0')}',
                                    icon: Icons.speed_rounded
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // --- Action List ---
                        _ProfileMenuTile(
                          icon: Icons.logout_rounded,
                          label: 'DEACTIVATE SESSION',
                          color: Colors.redAccent,
                          onPressed: () => _confirmSignOut(context, ref),
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

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('END SESSION?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
          content: const Text('You will be returned to the athlete recruitment screen.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('SIGN OUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ProfileMenuTile({required this.icon, required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
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
