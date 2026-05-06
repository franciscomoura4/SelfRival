import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/mock_repository.dart';
import '../../data/models/route_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/route_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;
  String? _selectedRouteId;

  // Default starting position (Lisbon)
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(38.7223, -9.1393),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // --- THE CRASH-PROOF GPS WAKEUP ---
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 14.0),
          ),
        );
      }
    } catch (e) {
      // SAFETY NET: If the Android Emulator's fake GPS crashes (Error 20),
      // the app safely ignores it and just uses the default map of Lisbon.
      debugPrint("Emulator GPS glitch caught safely: $e");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Set<Polyline> _buildPolylines(List<RouteMaster> routes) {
    return routes.map((route) {
      final isSelected = route.id == _selectedRouteId;
      return Polyline(
        polylineId: PolylineId(route.id),
        points: route.path,
        color: isSelected ? const Color(0xFF23A2D9) : Colors.grey.withOpacity(0.4),
        width: isSelected ? 6 : 4,
        zIndex: isSelected ? 1 : 0,
        consumeTapEvents: true,
        onTap: () => _selectRoute(route),
      );
    }).toSet();
  }

  void _selectRoute(RouteMaster route) {
    setState(() => _selectedRouteId = route.id);
    if (route.path.isNotEmpty) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(route.path.first, 15.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(routeProvider);
    final user = MockRepository.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,

      // --- THE SIDE MENU (DRAWER) ---
      drawer: Drawer(
        backgroundColor: Colors.grey.shade900,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF23A2D9)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.route, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text('My Routes', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('${routes.length} Saved Masters', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ...routes.map((route) {
              final minutes = (route.personalBestTime / 60).floor();
              final seconds = (route.personalBestTime % 60).toInt();
              return ListTile(
                leading: const Icon(Icons.map, color: Colors.grey),
                title: Text(route.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${route.distance} km • PB: $minutes:${seconds.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                  _selectRoute(route);    // Select and fly to the route
                },
                trailing: IconButton(
                  icon: const Icon(Icons.directions_run, color: Color(0xFF23A2D9)),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/run?routeId=${route.id}');
                  },
                ),
              );
            }),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.black87.withOpacity(0.7),
        elevation: 0,
        title: const Text('SelfRival', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF23A2D9),
              child: Text(user.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            polylines: _buildPolylines(routes),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController?.setMapStyle(_darkMapStyle);
            },
            onTap: (_) => setState(() => _selectedRouteId = null),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoadingLocation)
                    const Center(child: Padding(padding: EdgeInsets.only(bottom: 16.0), child: CircularProgressIndicator(color: Color(0xFF23A2D9)))),

                  // Free Run Button
                  SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions_run, size: 28),
                      label: const Text('Start Free Run', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23A2D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                      ),
                      onPressed: () => context.push('/run'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final String _darkMapStyle = '''
  [
    {"elementType": "geometry","stylers": [{"color": "#212121"}]},
    {"elementType": "labels.icon","stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},
    {"elementType": "labels.text.stroke","stylers": [{"color": "#212121"}]},
    {"featureType": "administrative","elementType": "geometry","stylers": [{"color": "#757575"}]},
    {"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2c2c2c"}]},
    {"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#8a8a8a"}]},
    {"featureType": "water","elementType": "geometry","stylers": [{"color": "#000000"}]}
  ]
  ''';
}