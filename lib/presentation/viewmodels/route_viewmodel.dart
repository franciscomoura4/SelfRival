import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/route_model.dart';
import '../../data/mock_repository.dart';

// This ViewModel manages the state of the user's Route Masters.
class RouteViewModel extends StateNotifier<List<RouteMaster>> {
  RouteViewModel() : super([]) {
    _loadRoutes();
  }

  // 1. Fetch routes from the database
  Future<void> _loadRoutes() async {
    // Simulating network delay for Firebase
    await Future.delayed(const Duration(milliseconds: 500));

    // Load from our mock database
    state = MockRepository.myRoutes;
  }

  // 2. Auto-Genesis: Save a new route after a Free Run
  Future<void> saveNewRoute(String name, double distance, double timeInSeconds) async {
    final newRoute = RouteMaster(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}', // Generate a fake unique ID
      name: name.isEmpty ? 'Unnamed Route' : name,
      geometry: 'mock_polyline_data', // Later, this will be real GPS coordinates
      personalBestTime: timeInSeconds,
      distance: distance,
    );

    // 1. Save to database (MockRepo for now, Firebase later)
    MockRepository.myRoutes.add(newRoute);

    // 2. Update the UI state instantly
    // We create a new list with the old items spread [...state] plus the new item
    state = [...state, newRoute];
  }
}

// Make the ViewModel accessible to the rest of the app
final routeProvider = StateNotifierProvider<RouteViewModel, List<RouteMaster>>((ref) {
  return RouteViewModel();
});