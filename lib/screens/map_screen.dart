import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  //final LatLng _initialPosition = const LatLng(-23.5557714, -46.6395571);
  final LatLng _initialPosition = const LatLng(31.963158, 35.930359);
  LatLng? _selectedPosition; // Store the selected position

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    debugPrint('Map created successfully');
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position; // Update the selected position
    });
    debugPrint('Tapped location: ${position.latitude}, ${position.longitude}');
  }

  void _confirmLocation() {
    if (_selectedPosition != null) {
      Navigator.of(context).pop(_selectedPosition); // Return the selected position
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation, // Confirm and return the location
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 11.0,
        ),
        onTap: _onMapTapped, // Handle user taps on the map
        markers: _selectedPosition == null ? {} : { Marker(
                  markerId: const MarkerId('selected-location'),
                  position: _selectedPosition!,
                ),
              },
      ),
    );
  }
}
