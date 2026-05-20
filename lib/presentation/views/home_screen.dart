import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  String? _selectedRouteId;
  LatLng _currentLocation = const LatLng(38.7223, -9.1393);

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
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation, 14.0);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  List<Polyline> _buildPolylines(List<RouteMaster> routes) {
    return routes.map((route) {
      final isSelected = route.id == _selectedRouteId;
      return Polyline(
        points: route.path,
        color: isSelected ? const Color(0xFF23A2D9) : Colors.grey.withOpacity(0.4),
        strokeWidth: isSelected ? 6.0 : 4.0,
      );
    }).toList();
  }

  void _selectRoute(RouteMaster route) {
    setState(() => _selectedRouteId = route.id);
    if (route.path.isNotEmpty) {
      _mapController.move(route.path.first, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routeProvider);
    final routes = routesState.value ?? [];
    final user = ref.watch(authProvider);

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
                  context.push('/route-details/${route.id}');
                },
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
              decoration: BoxDecoration(color: const Color(0xFF23A2D9).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.bar_chart, size: 20, color: Color(0xFF23A2D9)),
            ),
            onPressed: () => context.push('/stats'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF23A2D9),
                child: Text(
                  (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              onTap: (_, __) => setState(() => _selectedRouteId = null),
            ),
            children: [
              TileLayer(
                // This is the magic URL that makes the map look incredible and sleek black.
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.selfrival',
              ),
              PolylineLayer(
                polylines: _buildPolylines(routes),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.blue, blurRadius: 10)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
}