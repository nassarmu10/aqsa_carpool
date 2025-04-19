import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/location_utils.dart';
import 'ride_details_screen.dart';

class SearchRideScreen extends StatefulWidget {
  @override
  _SearchRideScreenState createState() => _SearchRideScreenState();
}

class _SearchRideScreenState extends State<SearchRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  String _originAddress = '';
  GeoPoint? _originLocation;
  String _destinationAddress = 'Al-Aqsa Mosque';
  GeoPoint _destinationLocation = GeoPoint(31.7781, 35.2358); // Default Al-Aqsa location
  DateTime _selectedDate = DateTime.now();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

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

  Future<void> _searchRides() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSearching = true;
        _hasSearched = true;
        _searchResults = [];
      });

      try {
        // Create date range for the selected date (entire day)
        DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
        DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

        // Base query for rides on the selected date
        Query ridesQuery = _firestore
            .collection('rides')
            .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('departureTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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
            GeoPoint rideDestination = data['destinationLocation'] ?? GeoPoint(0, 0);
            // Simple proximity check (can be improved with actual distance calculation)
            double distanceThreshold = 0.05; // Approximately 5km
            double latDiff = (_destinationLocation.latitude - rideDestination.latitude).abs();
            double lngDiff = (_destinationLocation.longitude - rideDestination.longitude).abs();
            
            if (latDiff > distanceThreshold || lngDiff > distanceThreshold) {
              continue; // Skip rides that aren't going to the selected destination area
            }
          }
          
          // Filter by origin if specified
          if (_originLocation != null) {
            GeoPoint rideOrigin = data['originLocation'] ?? GeoPoint(0, 0);
            // Simple proximity check
            double distanceThreshold = 0.05; // Approximately 5km
            double latDiff = (_originLocation!.latitude - rideOrigin.latitude).abs();
            double lngDiff = (_originLocation!.longitude - rideOrigin.longitude).abs();
            
            if (latDiff > distanceThreshold || lngDiff > distanceThreshold) {
              continue; // Skip rides that aren't starting from the selected origin area
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
                      for (String commonPlace in AppConstants.commonOrigins.take(3))
                        ActionChip(
                          avatar: Icon(Icons.place, size: 16),
                          label: Text(commonPlace),
                          onPressed: () async {
                            final result = await LocationUtils.geocodeAddress(commonPlace);
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
                      for (String commonPlace in AppConstants.commonDestinations.take(3))
                        ActionChip(
                          avatar: Icon(Icons.place, size: 16),
                          label: Text(commonPlace),
                          onPressed: () async {
                            final result = await LocationUtils.geocodeAddress(commonPlace);
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
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
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideDetailsScreen(rideId: ride['id']),
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
                Text(
                  '${ride['availableSeats']} seats available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
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
