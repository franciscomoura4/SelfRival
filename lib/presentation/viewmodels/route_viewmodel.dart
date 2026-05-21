import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/route_model.dart';
import '../../data/rest_repository.dart';
import 'auth_viewmodel.dart';

final restRepositoryProvider = Provider((ref) => RestRepository());
final activePathProvider = StateProvider<List<RoutePoint>>((ref) => []);
final targetRouteIdProvider = StateProvider<String?>((ref) => null); // 🟢 Knows if we are racing a Ghost!

class RouteViewModel extends StateNotifier<AsyncValue<List<RouteMaster>>> {
  final RestRepository _repository;
  final String _uid;
  RouteViewModel(this._repository, this._uid) : super(const AsyncValue.loading()) { fetchRoutes(); }

  Future<void> fetchRoutes() async {
    state = const AsyncValue.loading();
    try {
      final routes = await _repository.getRoutes(_uid);
      state = AsyncValue.data(routes);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> saveNewRoute(String name, double distance, double timeInSeconds, double elevation, List<RoutePoint> points) async {
    try {
      final newRoute = RouteMaster(
          id: '',
          name: name.isEmpty ? 'New Circuit' : name,
          distance: distance,
          personalBestTime: timeInSeconds,
          elevationGain: elevation,
          points: points
      );
      final savedRoute = await _repository.createRoute(_uid, newRoute);
      if (state is AsyncData) state = AsyncValue.data([...state.value!, savedRoute]);
    } catch (e) { print("Error saving route: $e"); }
  }

  Future<void> updatePersonalBest(String routeId, double newTime) async {
    try {
      await _repository.updateRoutePB(_uid, routeId, newTime);
      fetchRoutes();
    } catch (e) { print("Error updating PB: $e"); }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _repository.deleteRoute(_uid, routeId);
      if (state is AsyncData) {
        state = AsyncValue.data(state.value!.where((r) => r.id != routeId).toList());
      }
    } catch (e) {
      print("Error deleting route: $e");
    }
  }
}

final routeProvider = StateNotifierProvider<RouteViewModel, AsyncValue<List<RouteMaster>>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return RouteViewModel(ref.read(restRepositoryProvider), '');
  return RouteViewModel(ref.read(restRepositoryProvider), user.id);
});