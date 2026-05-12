import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(38.7223, -9.1393),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

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
    final routesState = ref.watch(routeProvider);
    final routes = routesState.value ?? []; // Safely extract the list
    final user = ref.watch(authProvider); // Safely read user from AuthViewModel

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                subtitle: Text('${route.distance.toStringAsFixed(2)} km • PB: $minutes:${seconds.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _selectRoute(route);
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withValues(alpha: 0.7) 
            : Colors.white.withValues(alpha: 0.7),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text('SELRIVAL', style: TextStyle(letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF23A2D9).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart, size: 20, color: Color(0xFF23A2D9)),
            ),
            onPressed: () => context.push('/stats'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF23A2D9),
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
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
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              if (isDarkMode) {
                _mapController?.setMapStyle(_darkMapStyle);
              } else {
                _mapController?.setMapStyle(null); // Reset to default/light
              }
            },
            onTap: (_) => setState(() => _selectedRouteId = null),
          ),

          if (routesState.isLoading)
            const Positioned(
              top: 100, left: 0, right: 0,
              child: Center(
                child: Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF23A2D9), strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text("Syncing Cloud Data...", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
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

                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23A2D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () => context.push('/run'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 32),
                          SizedBox(width: 8),
                          Text('START FREE RUN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        ],
                      ),
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