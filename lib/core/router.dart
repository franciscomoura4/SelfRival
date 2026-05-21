import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Views
import '../presentation/views/home_screen.dart';
import '../presentation/views/active_run_screen.dart';
import '../presentation/views/post_run_screen.dart';
import '../presentation/views/statistics_screen.dart';
import '../presentation/views/login_screen.dart';
import '../presentation/views/profile_screen.dart';
import '../presentation/views/route_details_screen.dart';

// ViewModels
import '../presentation/viewmodels/auth_viewmodel.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isGoingToLogin = state.uri.toString() == '/login';

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }
      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen()
      ),
      GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen()
      ),
      GoRoute(
        path: '/route-details/:routeId',
        builder: (context, state) {
          final routeId = state.pathParameters['routeId']!;
          return RouteDetailsScreen(routeId: routeId);
        },
      ),
      GoRoute(
        path: '/run',
        builder: (context, state) {
          final routeId = state.uri.queryParameters['routeId'];
          return ActiveRunScreen(routeId: routeId);
        },
      ),
      GoRoute(
        path: '/post-run',
        builder: (context, state) {
          final distance = double.tryParse(state.uri.queryParameters['distance'] ?? '0.0') ?? 0.0;
          final time = int.tryParse(state.uri.queryParameters['time'] ?? '0') ?? 0;
          final elevation = double.tryParse(state.uri.queryParameters['elevation'] ?? '0.0') ?? 0.0;
          final isCompleted = state.uri.queryParameters['isCompleted'] == 'true';
          return PostRunScreen(distance: distance, time: time, elevation: elevation, isCompleted: isCompleted);
        },
      ),
      GoRoute(
          path: '/stats',
          builder: (context, state) => const StatisticsScreen()
      ),
      GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen()
      ),
    ],
  );
});