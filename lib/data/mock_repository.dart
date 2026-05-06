import 'models/user_model.dart';
import 'models/route_model.dart';

class MockRepository {
  static final AppUser currentUser = AppUser(
    id: 'u1',
    name: 'Runner 01',
    email: 'runner@selfrival.com',
    achievements: ['First 5K', 'Speed Demon'],
  );

  static final List<RouteMaster> myRoutes = [
    RouteMaster(
      id: 'r1',
      name: 'River Loop',
      geometry: 'encoded_polyline_string_here',
      personalBestTime: 1452, // 24m 12s
      distance: 5.0,
    ),
    RouteMaster(
      id: 'r2',
      name: 'City Hills',
      geometry: 'encoded_polyline_string_here',
      personalBestTime: 2100, // 35m 00s
      distance: 6.2,
    ),
  ];
}