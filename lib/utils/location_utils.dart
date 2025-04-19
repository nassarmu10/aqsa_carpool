// lib/utils/location_utils.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'dart:async'; // For debounce functionality

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
  
  // Geocode address to get coordinates using OpenStreetMap
  static Future<LocationResult?> geocodeAddress(String address) async {
    try {
      final searchResult = await Nominatim.searchByName(
        query: address,
        limit: 1,
        addressDetails: true,
        extraTags: true,
        nameDetails: true,
      );
      
      if (searchResult.isNotEmpty) {
        final place = searchResult.first;
        return LocationResult(
          place.displayName,
          GeoPoint(place.lat, place.lon)
        );
      }
      
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }
  
  // Get address suggestions from OpenStreetMap
  static Future<List<Place>> getAddressSuggestions(String query) async {
    if (query.length < 3) return [];
    
    try {
      final searchResult = await Nominatim.searchByName(
        query: query,
        limit: 5,
        addressDetails: true,
        extraTags: true,
        nameDetails: true,
      );
      
      return searchResult;
    } catch (e) {
      print('Error getting address suggestions: $e');
      return [];
    }
  }
  
  // Show custom address search dialog with autocomplete
  static Future<LocationResult?> showAddressSearchDialog(
    BuildContext context, {
    List<String> suggestions = const [],
  }) async {
    return await showDialog<LocationResult?>(
      context: context,
      builder: (context) {
        return AddressSearchDialog(
          suggestions: suggestions,
        );
      },
    );
  }
}

class AddressSearchDialog extends StatefulWidget {
  final List<String> suggestions;
  
  const AddressSearchDialog({
    Key? key,
    this.suggestions = const [],
  }) : super(key: key);

  @override
  _AddressSearchDialogState createState() => _AddressSearchDialogState();
}

class _AddressSearchDialogState extends State<AddressSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Place> _autocompleteResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.length >= 3) {
        _getAutocompleteResults();
      } else {
        setState(() {
          _autocompleteResults = [];
        });
      }
    });
  }

  Future<void> _getAutocompleteResults() async {
    if (_searchController.text.length < 3) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final results = await LocationUtils.getAddressSuggestions(_searchController.text);
      
      if (mounted) {
        setState(() {
          _autocompleteResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error getting autocomplete results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Find Location'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter address',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _isLoading 
                    ? Container(
                        width: 20,
                        height: 20,
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) 
                    : null,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
            ),
            SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Use current location option
                  ListTile(
                    leading: Icon(Icons.my_location, color: Colors.blue),
                    title: Text('Use my current location'),
                    onTap: () async {
                      final locationResult = await LocationUtils.getCurrentLocation(context);
                      Navigator.of(context).pop(locationResult);
                    },
                  ),
                  
                  // Show suggested places
                  if (_searchController.text.isEmpty && widget.suggestions.isNotEmpty) ...[
                    Divider(),
                    Padding(
                      padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                      child: Text('Suggestions', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600]
                        ),
                      ),
                    ),
                    ...widget.suggestions.map((suggestion) => ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text(suggestion),
                      onTap: () async {
                        final locationResult = await LocationUtils.geocodeAddress(suggestion);
                        if (locationResult != null) {
                          Navigator.of(context).pop(locationResult);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not find location')),
                          );
                        }
                      },
                    )).toList(),
                  ],
                  
                  // Show autocomplete results
                  if (_autocompleteResults.isNotEmpty) ...[
                    Divider(),
                    ..._autocompleteResults.map((place) => ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text(place.displayName),
                      onTap: () {
                        Navigator.of(context).pop(LocationResult(
                          place.displayName,
                          GeoPoint(place.lat, place.lon)
                        ));
                      },
                    )).toList(),
                  ],
                  
                  // Show no results message
                  if (_isLoading == false && 
                      _searchController.text.length >= 3 && 
                      _autocompleteResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No locations found',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
            if (_searchController.text.isNotEmpty) {
              setState(() {
                _isLoading = true;
              });
              final locationResult = await LocationUtils.geocodeAddress(_searchController.text);
              setState(() {
                _isLoading = false;
              });
              Navigator.of(context).pop(locationResult);
            }
          },
          child: Text('SEARCH'),
        ),
      ],
    );
  }
}
