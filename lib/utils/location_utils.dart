// lib/utils/location_utils.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationResult {
  final String address;
  final GeoPoint geoPoint;

  LocationResult(this.address, this.geoPoint);
}

class LocationUtils {
  // Check and request location permissions
  static Future<bool> checkLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied')),
        );
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permissions permanently denied, please enable in settings'),
          action: SnackBarAction(
            label: 'SETTINGS',
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ),
      );
      return false;
    }
    
    return true;
  }

  // Get current location as LocationResult
  static Future<LocationResult?> getCurrentLocation(BuildContext context) async {
    if (!await checkLocationPermission(context)) {
      return null;
    }
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = _formatPlacemark(place);
        
        if (address.isEmpty) {
          address = '${position.latitude}, ${position.longitude}';
        }
        
        return LocationResult(
          address, 
          GeoPoint(position.latitude, position.longitude)
        );
      }
      
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return null;
    }
  }
  
  // Format a placemark into an address string
  static String _formatPlacemark(Placemark place) {
    List<String> components = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      components.add(place.street!);
    }
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      components.add(place.locality!);
    }
    
    if (place.country != null && place.country!.isNotEmpty) {
      components.add(place.country!);
    }
    
    return components.join(', ');
  }
  
  // Geocode address to get coordinates
  static Future<LocationResult?> geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        return LocationResult(
          address,
          GeoPoint(location.latitude, location.longitude)
        );
      }
      
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }
  
  // Show custom address search dialog
  static Future<LocationResult?> showAddressSearchDialog(
    BuildContext context, {
    List<String> suggestions = const [],
  }) async {
    TextEditingController searchController = TextEditingController();
    List<String> filteredSuggestions = [];
    List<String> recentSearches = [];
    
    // Get recent searches from local storage if needed
    
    return showDialog<LocationResult?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void filterSuggestions(String query) {
              setState(() {
                if (query.isEmpty) {
                  filteredSuggestions = [];
                } else {
                  filteredSuggestions = suggestions
                      .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                      .toList();
                  
                  // Add some generated suggestions
                  if (query.length > 2) {
                    filteredSuggestions.add('$query Street');
                    filteredSuggestions.add('$query District');
                  }
                  
                  // Limit to 5 suggestions
                  filteredSuggestions = filteredSuggestions.take(5).toList();
                }
              });
            }
            
            return AlertDialog(
              title: Text('Find Location'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Enter address',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: filterSuggestions,
                    ),
                    SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Use my current location option
                          ListTile(
                            leading: Icon(Icons.my_location, color: Colors.blue),
                            title: Text('Use my current location'),
                            onTap: () async {
                              final locationResult = await getCurrentLocation(context);
                              Navigator.of(context).pop(locationResult);
                            },
                          ),
                          Divider(),
                          ...filteredSuggestions.map((suggestion) => ListTile(
                            leading: Icon(Icons.location_on),
                            title: Text(suggestion),
                            onTap: () async {
                              final locationResult = await geocodeAddress(suggestion);
                              if (locationResult != null) {
                                Navigator.of(context).pop(locationResult);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not find location')),
                                );
                              }
                            },
                          )).toList(),
                          
                          if (recentSearches.isNotEmpty) ...[
                            Divider(),
                            Padding(
                              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                              child: Text('Recent Searches', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600]
                                ),
                              ),
                            ),
                            ...recentSearches.map((recent) => ListTile(
                              leading: Icon(Icons.history),
                              title: Text(recent),
                              onTap: () async {
                                final locationResult = await geocodeAddress(recent);
                                Navigator.of(context).pop(locationResult);
                              },
                            )).toList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (searchController.text.isNotEmpty) {
                      final locationResult = await geocodeAddress(searchController.text);
                      Navigator.of(context).pop(locationResult);
                    }
                  },
                  child: Text('SEARCH'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
