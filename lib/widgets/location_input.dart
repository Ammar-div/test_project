//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
//import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_project/screens/map_screen.dart';

class LocationInput extends StatefulWidget {
  final Function onSelectLocation;

  const LocationInput({required this.onSelectLocation, Key? key}) : super(key: key);

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  var _isGettingLocation = false;
  String? _previewImageUrl;

  Future<void> _getCurrentLocation() async {
    final location = Location();

    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check for service and permissions
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled.');
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permissions are denied.');
        }
      }

      // Get the current location
      final locationData = await location.getLocation();
      await _savePlace(locationData.latitude!, locationData.longitude!);
    } catch (error) {
      setState(() {
        _isGettingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $error')),
      );
      return; // Exit to avoid further processing
    }

    setState(() {
      _isGettingLocation = false;
    });
  }

  Future<void> _savePlace(double latitude, double longitude) async {
    try {
      // Reverse geocoding API call
      //final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=AIzaSyDlu777DsFcr2_2yVZUoieiaYS94UxT_Do');
      //final response = await http.get(url);
      //final resData = json.decode(response.body);
      //final address = resData['results'][0]['formatted_address'];

      // Create the static map URL
      final staticMapImageUrl =
          'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:A%7C$latitude,$longitude&key=AIzaSyDlu777DsFcr2_2yVZUoieiaYS94UxT_Do';

      setState(() {
        _previewImageUrl = staticMapImageUrl;
      });

      widget.onSelectLocation(latitude, longitude); // Pass data to parent widget
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process location data: $error')),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: _isGettingLocation
              ? const CircularProgressIndicator() // Show spinner while loading
              : _previewImageUrl == null
                  ? Text(
                      'No location chosen',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    )
                  : Image.network(
                      _previewImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.location_on),
                  onPressed: _getCurrentLocation,
                  label: const Text('Get Current Location'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.map),
                  onPressed: () async {
                    // Navigate to MapScreen and get the selected location
                    final LatLng? selectedLocation =
                        await Navigator.of(context).push<LatLng>(
                      MaterialPageRoute(builder: (ctx) => const MapScreen()),
                    );

                    if (selectedLocation == null) {
                      return; // User canceled the selection
                    }

                    // Use the location to update the preview
                    await _savePlace(
                      selectedLocation.latitude,
                      selectedLocation.longitude,
                    );
                  },
                  label: const Text('Select on Map'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
