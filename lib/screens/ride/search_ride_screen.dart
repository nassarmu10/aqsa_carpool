import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/location_utils.dart';
import 'ride_details_screen.dart';

// Add OpenRouteService client
class OpenRouteService {
  final String apiKey;
  final String baseUrl = 'https://api.openrouteservice.org/v2';

  OpenRouteService({required this.apiKey});

  /// Calculate a route between two points
  Future<Map<String, dynamic>> getRoute({
    required LatLng startPoint,
    required LatLng endPoint,
  }) async {
    return getRouteWithStops(
      startPoint: startPoint,
      endPoint: endPoint,
      stops: [],
    );
  }

  /// Calculate a route between two points with intermediate stops
  Future<Map<String, dynamic>> getRouteWithStops({
    required LatLng startPoint,
    required LatLng endPoint,
    required List<LatLng> stops,
  }) async {
    // Build coordinates list with start, stops, and end
    final List<List<double>> coordinates = [
      [startPoint.longitude, startPoint.latitude],
      ...stops.map((stop) => [stop.longitude, stop.latitude]),
      [endPoint.longitude, endPoint.latitude],
    ];

    final url = '$baseUrl/directions/driving-car';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey,
        },
        body: jsonEncode({
          'coordinates': coordinates,
          'format': 'geojson',
          'instructions': true,
          'units': 'km',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to calculate route: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calculating route: $e');
    }
  }

  /// Decodes a route's geometry to a list of coordinates
  List<LatLng> decodeRoute(Map<String, dynamic> routeData) {
    List<LatLng> points = [];

    try {
      // Extract coordinates from the GeoJSON response
      final features = routeData['features'] as List;
      if (features.isNotEmpty) {
        final geometry = features[0]['geometry'];
        final coordinates = geometry['coordinates'] as List;

        for (var coord in coordinates) {
          // Note: GeoJSON uses [longitude, latitude] format
          points.add(LatLng(coord[1], coord[0]));
        }
      }
    } catch (e) {
      print('Error decoding route: $e');
    }

    return points;
  }

  /// Get route summary information
  Map<String, dynamic> getRouteSummary(Map<String, dynamic> routeData) {
    try {
      print('SIIIIIIIIIIIII');
      final features = routeData['routes'][0];
      print('SIIIIIIIIIIIII');

      var totalDistance = features["summary"]["distance"];
      var totalDuration = features["summary"]["duration"];
      return {
        'distance': totalDistance, // in meters
        'duration': totalDuration, // in seconds
        'formatted': {
          'distance': '${(totalDistance).toStringAsFixed(2)} km',
          'duration': '${(totalDuration / 60).toStringAsFixed(0)} min',
        }
      };
    } catch (e) {
      print('Error extracting route summary: $e');
    }

    return {
      'distance': 0,
      'duration': 0,
      'formatted': {'distance': '0 km', 'duration': '0 min'}
    };
  }
}

class SearchRideScreen extends StatefulWidget {
  @override
  _SearchRideScreenState createState() => _SearchRideScreenState();
}

class _SearchRideScreenState extends State<SearchRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Add OpenRouteService instance
  final OpenRouteService _routeService = OpenRouteService(
      apiKey: '5b3ce3597851110001cf6248e833dd25d0ec42d98388e523c95b03e3');

  String _originAddress = '';
  GeoPoint? _originLocation;
  String _destinationAddress = 'Al-Aqsa Mosque';
  GeoPoint _destinationLocation =
      GeoPoint(31.7781, 35.2358); // Default Al-Aqsa location
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Map to store calculated routes for each ride
  Map<String, Map<String, dynamic>> _routeCache = {};

  // Map to store calculated routes for each ride
  Map<String, Map<String, dynamic>> _routeWithStopsCache = {};
  bool _isCalculatingRoutes = false;

  @override
  void initState() {
    super.initState();
    _destinationController.text = _destinationAddress;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectOrigin() async {
    final result = await LocationUtils.showAddressSearchDialog(
      context,
      suggestions: AppConstants.commonOrigins,
    );

    if (result != null) {
      setState(() {
        _originAddress = result.address;
        _originLocation = result.geoPoint;
        _originController.text = result.address;
      });
    }
  }

  Future<void> _selectDestination() async {
    final result = await LocationUtils.showAddressSearchDialog(
      context,
      suggestions: AppConstants.commonDestinations,
    );

    if (result != null) {
      setState(() {
        _destinationAddress = result.address;
        _destinationLocation = result.geoPoint;
        _destinationController.text = result.address;
      });
    }
  }

  // Add method to calculate routes for all search results
  Future<void> _calculateRoutesForResults() async {
    if (_searchResults.isEmpty || _originLocation == null) return;

    setState(() {
      _isCalculatingRoutes = true;
    });

    try {
      // Use temporary maps to avoid multiple UI updates
      Map<String, Map<String, dynamic>> newRouteCache = {};
      Map<String, Map<String, dynamic>> newRouteWithStopsCache = {};

      for (var ride in _searchResults) {
        String rideId = ride['id'];

        // Skip if we already have both routes in cache
        if (_routeCache.containsKey(rideId) &&
            _routeWithStopsCache.containsKey(rideId)) {
          newRouteCache[rideId] = _routeCache[rideId]!;
          newRouteWithStopsCache[rideId] = _routeWithStopsCache[rideId]!;
          continue;
        }

        GeoPoint originLocation = ride['originLocation'];
        GeoPoint destinationLocation = ride['destinationLocation'];

        // Convert GeoPoint to LatLng
        LatLng rideStartPoint =
            LatLng(originLocation.latitude, originLocation.longitude);
        LatLng rideEndPoint =
            LatLng(destinationLocation.latitude, destinationLocation.longitude);

        try {
          // Calculate direct route (from ride origin to ride destination)
          if (!_routeCache.containsKey(rideId)) {
            final routeData = await _routeService.getRoute(
              startPoint: rideStartPoint,
              endPoint: rideEndPoint,
            );

            final summary = _routeService.getRouteSummary(routeData);
            newRouteCache[rideId] = summary;
          } else {
            newRouteCache[rideId] = _routeCache[rideId]!;
          }

          // Calculate route with user's location as a stop
          if (!_routeWithStopsCache.containsKey(rideId)) {
            // Add user's current location as a stop
            LatLng userLocation =
                LatLng(_originLocation!.latitude, _originLocation!.longitude);

            final routeWithStop = await _routeService.getRouteWithStops(
              startPoint: rideStartPoint,
              endPoint: rideEndPoint,
              stops: [userLocation],
            );

            final summaryWithStop =
                _routeService.getRouteSummary(routeWithStop);
            newRouteWithStopsCache[rideId] = summaryWithStop;
          } else {
            newRouteWithStopsCache[rideId] = _routeWithStopsCache[rideId]!;
          }
        } catch (e) {
          print('Error calculating route for ride $rideId: $e');
          // Add placeholder for failed route calculations
          if (!newRouteCache.containsKey(rideId)) {
            newRouteCache[rideId] = {
              'formatted': {'distance': 'N/A', 'duration': 'N/A'},
              'error': true
            };
          }
          if (!newRouteWithStopsCache.containsKey(rideId)) {
            newRouteWithStopsCache[rideId] = {
              'formatted': {'distance': 'N/A', 'duration': 'N/A'},
              'error': true
            };
          }
        }
      }

      // Update the cache with all new routes at once
      if (mounted) {
        setState(() {
          _routeCache = {..._routeCache, ...newRouteCache};
          _routeWithStopsCache = {
            ..._routeWithStopsCache,
            ...newRouteWithStopsCache
          };
          _isCalculatingRoutes = false;
        });
      }
    } catch (e) {
      print('Error in route calculation: $e');
      if (mounted) {
        setState(() {
          _isCalculatingRoutes = false;
        });
      }
    }
  }

  // Calculate a single route (for use with the user's selected origin/destination)
  // Future<Map<String, dynamic>?> _calculateUserRoute() async {
  //   if (_originLocation == null || _destinationLocation == null) return null;

  //   try {
  //     LatLng startPoint =
  //         LatLng(_originLocation!.latitude, _originLocation!.longitude);
  //     LatLng endPoint =
  //         LatLng(_destinationLocation.latitude, _destinationLocation.longitude);

  //     final routeData = await _routeService.getRoute(
  //       startPoint: startPoint,
  //       endPoint: endPoint,
  //     );

  //     return _routeService.getRouteSummary(routeData);
  //   } catch (e) {
  //     print('Error calculating user route: $e');
  //     return null;
  //   }
  // }

  Future<void> _searchRides() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSearching = true;
        _hasSearched = true;
        _searchResults = [];
        _routeCache = {}; // Clear route cache when starting a new search
      });

      try {
        // Create date range for the selected date (entire day)
        DateTime startOfDay = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
        DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, 23, 59, 59);

        // Base query for rides on the selected date
        Query ridesQuery = _firestore
            .collection('rides')
            .where('departureTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('departureTime',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .where('isCompleted', isEqualTo: false)
            .where('availableSeats', isGreaterThan: 0);

        // Execute the query
        QuerySnapshot snapshot = await ridesQuery.get();

        // Process results
        List<Map<String, dynamic>> results = [];

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Filter by destination if searching for a specific one
          if (_destinationLocation != null) {
            GeoPoint rideDestination =
                data['destinationLocation'] ?? GeoPoint(0, 0);
            // Simple proximity check (can be improved with actual distance calculation)
            double distanceThreshold = 0.05; // Approximately 5km
            double latDiff =
                (_destinationLocation.latitude - rideDestination.latitude)
                    .abs();
            double lngDiff =
                (_destinationLocation.longitude - rideDestination.longitude)
                    .abs();

            if (latDiff > distanceThreshold || lngDiff > distanceThreshold) {
              continue; // Skip rides that aren't going to the selected destination area
            }
          }

          results.add({
            'id': doc.id,
            ...data,
          });
        }

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // Calculate routes for all search results after setting search results
        if (results.isNotEmpty) {
          _calculateRoutesForResults();
        }
      } catch (e) {
        print('Error searching rides: $e');
        setState(() {
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for rides: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find a Ride'),
      ),
      body: Column(
        children: [
          // Search form
          Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _originController,
                    decoration: InputDecoration(
                      labelText: 'From',
                      hintText: 'Enter origin (optional)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: _selectOrigin,
                        tooltip: 'Search location',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: _selectOrigin,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (String commonPlace
                          in AppConstants.commonOrigins.take(3))
                        ActionChip(
                          avatar: Icon(Icons.place, size: 16),
                          label: Text(commonPlace),
                          onPressed: () async {
                            final result =
                                await LocationUtils.geocodeAddress(commonPlace);
                            if (result != null) {
                              setState(() {
                                _originAddress = result.address;
                                _originLocation = result.geoPoint;
                                _originController.text = result.address;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      labelText: 'To',
                      hintText: 'Enter destination',
                      prefixIcon: Icon(Icons.location_on),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: _selectDestination,
                        tooltip: 'Search location',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: _selectDestination,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a destination';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (String commonPlace
                          in AppConstants.commonDestinations.take(3))
                        ActionChip(
                          avatar: Icon(Icons.place, size: 16),
                          label: Text(commonPlace),
                          onPressed: () async {
                            final result =
                                await LocationUtils.geocodeAddress(commonPlace);
                            if (result != null) {
                              setState(() {
                                _destinationAddress = result.address;
                                _destinationLocation = result.geoPoint;
                                _destinationController.text = result.address;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text(DateFormat('EEEE, MMM dd, yyyy')
                              .format(_selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Search Rides',
                    onPressed: _searchRides,
                    icon: Icons.search,
                  ),
                ],
              ),
            ),
          ),

          // Route calculation indicator
          if (_isCalculatingRoutes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Calculating routes...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'Search for available rides',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_transfer,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'No rides found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try different search criteria',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> ride = _searchResults[index];
        DateTime departureTime = (ride['departureTime'] as Timestamp).toDate();
        String rideId = ride['id'];

        // Get route info from cache if available
        Map<String, dynamic>? directRouteInfo = _routeCache[rideId];
        Map<String, dynamic>? pickupRouteInfo = _routeWithStopsCache[rideId];

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideDetailsScreen(
                    rideId: ride['id'],
                    directRouteInfo: directRouteInfo,
                    pickupRouteInfo: pickupRouteInfo,
                  ),
                ),
              );
            },
            title: Text(
              '${ride['originAddress']} to ${ride['destinationAddress']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text('Driver: ${ride['driverName']}'),
                SizedBox(height: 4),
                Text(
                  'Departure: ${DateFormat('MMM dd, yyyy - hh:mm a').format(departureTime)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${ride['availableSeats']} seats available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),

                // Show direct route info
                if (directRouteInfo != null &&
                    directRouteInfo['formatted'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'Direct: ${directRouteInfo['formatted']['distance']} • ${directRouteInfo['formatted']['duration']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                // Show pickup route info if origin is selected
                if (_originLocation != null &&
                    pickupRouteInfo != null &&
                    pickupRouteInfo['formatted'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.transfer_within_a_station,
                            size: 16, color: Colors.orange[700]),
                        SizedBox(width: 4),
                        Text(
                          'With pickup: ${pickupRouteInfo['formatted']['distance']} • ${pickupRouteInfo['formatted']['duration']}',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  )
                else if (_originLocation != null && _isCalculatingRoutes)
                  Text(
                    'Calculating routes...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        );
      },
    );
  }
}
