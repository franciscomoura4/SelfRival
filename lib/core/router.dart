import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Views
import '../presentation/views/home_screen.dart';
import '../presentation/views/active_run_screen.dart';
import '../presentation/views/post_run_screen.dart';
import '../presentation/views/statistics_screen.dart';
import '../presentation/views/login_screen.dart';

// ViewModels
import '../presentation/viewmodels/auth_viewmodel.dart';

// Wrap GoRouter in a provider so it can read the Auth State dynamically
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login', // Always evaluate from the login page first

    // REDIRECT LOGIC: This runs on every screen change and state change
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isGoingToLogin = state.uri.toString() == '/login';

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login'; // Force them to login
      }
      if (isLoggedIn && isGoingToLogin) {
        return '/'; // Already logged in? Send to Home dashboard
      }
      return null; // No redirect needed, let them go to their destination
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
        path: '/run',
        builder: (context, state) {
          // Extracts the routeId if we are racing a specific route
          final routeId = state.uri.queryParameters['routeId'];
          return ActiveRunScreen(routeId: routeId);
        },
      ),
      GoRoute(
          path: '/post-run',
          builder: (context, state) => const PostRunScreen()
      ),
      GoRoute(
          path: '/stats',
          builder: (context, state) => const StatisticsScreen()
      ),
    ],
  );
});