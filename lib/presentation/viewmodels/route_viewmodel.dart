import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_model.dart';
import '../../data/mock_repository.dart';

class RouteViewModel extends StateNotifier<List<RouteMaster>> {
  RouteViewModel() : super([]) {
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    state = MockRepository.myRoutes;
  }

  Future<void> saveNewRoute(String name, double distance, double timeInSeconds) async {
    final newRoute = RouteMaster(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isEmpty ? 'Unnamed Route' : name,
      personalBestTime: timeInSeconds,
      distance: distance,
      // Faking a newly drawn route path near the others
      path: const [
        LatLng(38.7369, -9.1426),
        LatLng(38.7410, -9.1480),
        LatLng(38.7450, -9.1500),
      ],
    );

    MockRepository.myRoutes.add(newRoute);
    state = [...state, newRoute];
  }
}

final routeProvider = StateNotifierProvider<RouteViewModel, List<RouteMaster>>((ref) {
  return RouteViewModel();
});