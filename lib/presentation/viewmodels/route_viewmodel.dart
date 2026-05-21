import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/route_model.dart';
import '../../data/rest_repository.dart';
import '../../core/similarity_service.dart';
import 'auth_viewmodel.dart';

final restRepositoryProvider = Provider((ref) => RestRepository());
final activePathProvider = StateProvider<List<RoutePoint>>((ref) => []);
final targetRouteIdProvider = StateProvider<String?>((ref) => null);

class RouteViewModel extends StateNotifier<AsyncValue<List<AppRoute>>> {
  final RestRepository _repository;
  final String _uid;

  RouteViewModel(this._repository, this._uid)
      : super(const AsyncValue.loading()) {
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    state = const AsyncValue.loading();
    try {
      final routes = await _repository.getRoutes(_uid);
      state = AsyncValue.data(routes);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Saves a free run: creates a new route whose canonical circuit is the
  /// recorded GPS trace, then adds the first activity to it.
  Future<void> saveFreeRun(
    String name,
    double distance,
    double timeInSeconds,
    double elevation,
    List<RoutePoint> points, {
    int stepCount = 0,
  }) async {
    if (_uid.isEmpty) return;
    try {
      final newRoute = AppRoute(
        id: '',
        name: name.isEmpty ? 'New Circuit' : name,
        distance: distance,
        elevationGain: elevation,
        circuit: points,
        activities: [],
      );
      final savedRoute = await _repository.createRoute(_uid, newRoute);

      final avgSpeed =
          timeInSeconds > 0 ? distance / (timeInSeconds / 3600) : 0.0;
      final activity = Activity(
        id: '',
        avgSpeed: avgSpeed,
        distance: distance,
        time: timeInSeconds,
        elevationGain: elevation,
        date: DateTime.now(),
        points: points,
        stepCount: stepCount,
      );
      final savedActivity =
          await _repository.addActivity(_uid, savedRoute.id, activity);

      final routeWithActivity = AppRoute(
        id: savedRoute.id,
        name: savedRoute.name,
        distance: savedRoute.distance,
        elevationGain: savedRoute.elevationGain,
        circuit: savedRoute.circuit,
        activities: [savedActivity],
      );
      if (state is AsyncData) {
        state = AsyncValue.data([...state.value!, routeWithActivity]);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving free run: $e');
    }
  }

  /// Saves a ghost run result.
  ///
  /// Returns `true` if the activity was appended to the existing [targetRouteId]
  /// (similarity ≥ 70%), or `false` if a new route was created.
  Future<bool> saveGhostRun(
    String targetRouteId,
    double distance,
    double timeInSeconds,
    double elevation,
    List<RoutePoint> points, {
    int stepCount = 0,
  }) async {
    if (_uid.isEmpty) return false;
    try {
      final routes = state.value ?? [];
      final targetRoute = routes.firstWhere(
        (r) => r.id == targetRouteId,
        orElse: () => throw Exception('Target route not found'),
      );

      final avgSpeed =
          timeInSeconds > 0 ? distance / (timeInSeconds / 3600) : 0.0;
      final activity = Activity(
        id: '',
        avgSpeed: avgSpeed,
        distance: distance,
        time: timeInSeconds,
        elevationGain: elevation,
        date: DateTime.now(),
        points: points,
        stepCount: stepCount,
      );

      final similar =
          SimilarityService.isSimilar(points, targetRoute.circuit);

      if (similar) {
        final savedActivity =
            await _repository.addActivity(_uid, targetRouteId, activity);
        final updatedRoute = AppRoute(
          id: targetRoute.id,
          name: targetRoute.name,
          distance: targetRoute.distance,
          elevationGain: targetRoute.elevationGain,
          circuit: targetRoute.circuit,
          activities: [savedActivity, ...targetRoute.activities],
        );
        if (state is AsyncData) {
          state = AsyncValue.data(
            state.value!
                .map((r) => r.id == targetRouteId ? updatedRoute : r)
                .toList(),
          );
        }
        return true;
      } else {
        // Path diverged — create a new route for this activity
        final newRoute = AppRoute(
          id: '',
          name: 'New Circuit',
          distance: distance,
          elevationGain: elevation,
          circuit: points,
          activities: [],
        );
        final savedRoute = await _repository.createRoute(_uid, newRoute);
        final savedActivity =
            await _repository.addActivity(_uid, savedRoute.id, activity);
        final routeWithActivity = AppRoute(
          id: savedRoute.id,
          name: savedRoute.name,
          distance: savedRoute.distance,
          elevationGain: savedRoute.elevationGain,
          circuit: savedRoute.circuit,
          activities: [savedActivity],
        );
        if (state is AsyncData) {
          state = AsyncValue.data([...state.value!, routeWithActivity]);
        }
        return false;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving ghost run: $e');
      return false;
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _repository.deleteRoute(_uid, routeId);
      if (state is AsyncData) {
        state = AsyncValue.data(
            state.value!.where((r) => r.id != routeId).toList());
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting route: $e');
    }
  }
}

final routeProvider =
    StateNotifierProvider<RouteViewModel, AsyncValue<List<AppRoute>>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) {
    return RouteViewModel(ref.read(restRepositoryProvider), '');
  }
  return RouteViewModel(ref.read(restRepositoryProvider), user.id);
});