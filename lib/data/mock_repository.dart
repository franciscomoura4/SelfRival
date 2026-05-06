import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'models/route_model.dart';
import 'models/user_model.dart';

class MockRepository {
  static final currentUser = AppUser(id: 'u1', name: 'Runner 01', email: 'test@test.com');

  static final List<RouteMaster> myRoutes = [
    RouteMaster(
      id: 'r1',
      name: 'River Loop',
      distance: 5.2,
      personalBestTime: 1560, // 26 minutes
      path: const [
        LatLng(38.7071, -9.1354), // Praça do Comércio
        LatLng(38.7056, -9.1415), // Cais do Sodré
        LatLng(38.7011, -9.1605), // Santos
        LatLng(38.6961, -9.1764), // Alcântara
      ],
    ),
    RouteMaster(
      id: 'r2',
      name: 'City Hills',
      distance: 3.8,
      personalBestTime: 1240, // ~20 minutes
      path: const [
        LatLng(38.7192, -9.1388), // Avenida da Liberdade
        LatLng(38.7254, -9.1501), // Marquês de Pombal
        LatLng(38.7335, -9.1542), // Parque Eduardo VII
      ],
    ),
  ];
}