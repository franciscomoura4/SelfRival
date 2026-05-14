import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_model.dart';
import '../../data/rest_repository.dart';
import 'auth_viewmodel.dart';

final restRepositoryProvider = Provider((ref) => RestRepository());
final activePathProvider = StateProvider<List<LatLng>>((ref) => []);
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

  //Update PB in Firebase and refresh state
  Future<void> updatePersonalBest(String routeId, double newTime) async {
    try {
      await _repository.updateRoutePB(_uid, routeId, newTime);
      fetchRoutes(); // Refresh the list so the new PB shows in the menu
    } catch (e) { print("Error updating PB: $e"); }
  }
}

final routeProvider = StateNotifierProvider<RouteViewModel, AsyncValue<List<RouteMaster>>>((ref) {
  final user = ref.watch(authProvider);
  final uid = user?.id ?? '';
  return RouteViewModel(ref.read(restRepositoryProvider), uid);
});