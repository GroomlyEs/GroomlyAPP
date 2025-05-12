import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = const LatLng(40.4168, -3.7038); // Madrid como fallback
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  final BusinessService _businessService = BusinessService();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadBusinessMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition,
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBusinessMarkers() async {
    try {
      final businesses = await _businessService.getBusinessesWithLocations();
      
      for (var business in businesses) {
        if (business['latitude'] != null && business['longitude'] != null) {
          final marker = Marker(
            markerId: MarkerId(business['id'].toString()),
            position: LatLng(business['latitude'], business['longitude']),
            infoWindow: InfoWindow(
              title: business['name'],
              snippet: business['address'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          );
          
          setState(() {
            _markers.add(marker);
          });
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error cargando marcadores de negocios: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Barberías'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition, 14),
          );
        },
        backgroundColor: const Color(0xFF143E40),
        child: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class BusinessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getBusinessesWithLocations() async {
    try {
      final response = await _supabase
          .from('barbershops')
          .select('id, name, address, city, cover_url, logo_url, rating, location')
          .not('location', 'is', null)
          .order('name', ascending: true);

      final businesses = List<Map<String, dynamic>>.from(response);

      return businesses.map((business) {
        if (business['location'] != null) {
          try {
            final locationStr = business['location'].toString();
            final regex = RegExp(r'POINT\(([-\d.]+) ([-\d.]+)\)');
            final match = regex.firstMatch(locationStr);
            
            if (match != null && match.groupCount >= 2) {
              business['longitude'] = double.parse(match.group(1)!);
              business['latitude'] = double.parse(match.group(2)!);
            }
          } catch (e) {
            debugPrint('Error al parsear ubicación: $e');
          }
        }
        return business;
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener negocios con ubicación: ${e.toString()}');
      throw Exception('Error al obtener negocios con ubicación: ${e.toString()}');
    }
  }
}