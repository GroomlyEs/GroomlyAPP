import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'business_service.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  late Future<List<Map<String, dynamic>>> _businessesFuture;
  latlong.LatLng? _currentPosition;
  bool _isLoading = true;
  int _selectedRadius = 5;

  @override
  void initState() {
    super.initState();
    _businessesFuture = Provider.of<BusinessService>(context, listen: false)
        .getBusinessesWithLocations();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentPosition = const latlong.LatLng(41.3854, 2.1760);
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentPosition = latlong.LatLng(41.3854, 2.1760);
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentPosition = latlong.LatLng(41.3854, 2.1760);
        _isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentPosition = latlong.LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentPosition = latlong.LatLng(41.3854, 2.1760);
        _isLoading = false;
      });
    }
  }

  void _centerMapOnUser() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barberías cercanas'),
        backgroundColor: const Color(0xFF143E40),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerMapOnUser,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _businessesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No se encontraron barberías con ubicación'),
                        TextButton(
                          onPressed: _refreshData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final businesses = snapshot.data!;
                return _buildMap(businesses);
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'search_btn',
            backgroundColor: const Color(0xFF143E40),
            child: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showProximitySearchDialog(context),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'refresh_btn',
            backgroundColor: const Color(0xFF143E40),
            mini: true,
            child: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> businesses) {
    final markers = businesses.where((business) {
      return business['latitude'] != null && business['longitude'] != null;
    }).map((business) {
      final lat = double.tryParse(business['latitude'].toString()) ?? 41.3854;
      final lng = double.tryParse(business['longitude'].toString()) ?? 2.1760;
      final latLng = latlong.LatLng(lat, lng);

      print('Marker: ${business['name']} at $lat, $lng');

      return Marker(
        point: latLng,
        width: 40,
        height: 40,
        builder: (ctx) => GestureDetector(
          onTap: () => _showBusinessInfo(business),
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }).toList();

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 30,
          height: 30,
          builder: (ctx) => const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 30,
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentPosition ?? latlong.LatLng(41.3854, 2.1760),
        zoom: 13,
        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.groomly_es',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  void _showBusinessInfo(Map<String, dynamic> business) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                business['name'] ?? 'Nombre no disponible',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(business['address'] ?? 'Dirección no disponible'),
              if (business['rating'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(business['rating'].toString()),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF143E40),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Ver detalles', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/business',
                    arguments: business['id'],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _getCurrentLocation();
    setState(() {
      _businessesFuture = Provider.of<BusinessService>(context, listen: false)
          .getBusinessesWithLocations();
      _isLoading = false;
    });
  }

  Future<void> _showProximitySearchDialog(BuildContext context) async {
    await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Buscar por proximidad'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona el radio de búsqueda (km):'),
                Slider(
                  min: 1,
                  max: 20,
                  divisions: 19,
                  value: _selectedRadius.toDouble(),
                  label: '$_selectedRadius km',
                  onChanged: (value) {
                    setState(() {
                      _selectedRadius = value.round();
                    });
                  },
                ),
                Text('Radio seleccionado: $_selectedRadius km'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (_currentPosition != null) {
                    final nearby = await Provider.of<BusinessService>(context, listen: false)
                        .getNearbyBusinesses(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                          _selectedRadius,
                        );

                    if (nearby.isNotEmpty) {
                      final bounds = _calculateBounds(nearby);
                      _mapController.fitBounds(
                        bounds,
                        options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se encontraron barberías en el radio seleccionado')),
                      );
                    }
                  }
                },
                child: const Text('Buscar'),
              ),
            ],
          );
        },
      ),
    );
  }

  LatLngBounds _calculateBounds(List<Map<String, dynamic>> businesses) {
    double? minLat, maxLat, minLng, maxLng;

    for (var business in businesses) {
      final lat = double.tryParse(business['latitude'].toString());
      final lng = double.tryParse(business['longitude'].toString());

      if (lat != null && lng != null) {
        minLat = minLat == null ? lat : min(minLat, lat);
        maxLat = maxLat == null ? lat : max(maxLat, lat);
        minLng = minLng == null ? lng : min(minLng, lng);
        maxLng = maxLng == null ? lng : max(maxLng, lng);
      }
    }

    if (_currentPosition != null) {
      minLat = min(minLat ?? _currentPosition!.latitude, _currentPosition!.latitude);
      maxLat = max(maxLat ?? _currentPosition!.latitude, _currentPosition!.latitude);
      minLng = min(minLng ?? _currentPosition!.longitude, _currentPosition!.longitude);
      maxLng = max(maxLng ?? _currentPosition!.longitude, _currentPosition!.longitude);
    }

    return LatLngBounds(
      latlong.LatLng(minLat ?? 41.3854, minLng ?? 2.1760),
      latlong.LatLng(maxLat ?? 41.3854, maxLng ?? 2.1760),
    );
  }
}
