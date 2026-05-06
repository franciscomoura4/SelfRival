import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_model.dart';
import '../../data/rest_repository.dart';

final restRepositoryProvider = Provider((ref) => RestRepository());

// Notice we use AsyncValue here to handle loading states automatically!
class RouteViewModel extends StateNotifier<AsyncValue<List<RouteMaster>>> {
  final RestRepository _repository;

  RouteViewModel(this._repository) : super(const AsyncValue.loading()) {
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    state = const AsyncValue.loading();
    try {
      final routes = await _repository.getRoutes();
      state = AsyncValue.data(routes);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> saveNewRoute(String name, double distance, double timeInSeconds, List<LatLng> actualPath) async {
    try {
      final newRoute = RouteMaster(
        id: '', // Firebase generates this
        name: name.isEmpty ? 'New Route' : name,
        distance: distance,
        personalBestTime: timeInSeconds,
        path: actualPath,
      );

      final savedRoute = await _repository.createRoute(newRoute);

      // Add the new route to the screen immediately
      if (state is AsyncData) {
        state = AsyncValue.data([...state.value!, savedRoute]);
      }
    } catch (e) {
      print("Error saving route: $e");
    }
  }
}

final routeProvider = StateNotifierProvider<RouteViewModel, AsyncValue<List<RouteMaster>>>((ref) {
  return RouteViewModel(ref.read(restRepositoryProvider));
});