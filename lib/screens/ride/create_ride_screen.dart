import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/location_utils.dart';
import '../../models/ride_model.dart';

class CreateRideScreen extends StatefulWidget {
  @override
  _CreateRideScreenState createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String _originAddress = '';
  GeoPoint? _originLocation;
  String _destinationAddress = 'Al-Aqsa Mosque';
  GeoPoint _destinationLocation =
      GeoPoint(31.7781, 35.2358); // Default Al-Aqsa location
  DateTime _departureDate = DateTime.now();
  TimeOfDay _departureTime = TimeOfDay.now();
  int _availableSeats = 3;
  String? _notes;
  bool _isLoading = false;

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
      initialDate: _departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _departureDate) {
      setState(() {
        _departureDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (picked != null && picked != _departureTime) {
      setState(() {
        _departureTime = picked;
      });
    }
  }

  DateTime _combineDateTime() {
    return DateTime(
      _departureDate.year,
      _departureDate.month,
      _departureDate.day,
      _departureTime.hour,
      _departureTime.minute,
    );
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

  Future<void> _createRide() async {
    if (_formKey.currentState!.validate()) {
      if (_originLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a valid origin location')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Get user name from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        String driverName = userDoc.exists
            ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
            : 'Unknown';

        // Create ride document with GeoPoints
        DocumentReference rideRef = await _firestore.collection('rides').add({
          'driverId': currentUser.uid,
          'driverName': driverName,
          'originAddress': _originAddress,
          'originLocation': _originLocation,
          'destinationAddress': _destinationAddress,
          'destinationLocation': _destinationLocation,
          'departureTime': Timestamp.fromDate(_combineDateTime()),
          'availableSeats': _availableSeats,
          'notes': _notes,
          'passengers': [],
          'pendingRequests': [],
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update the document with its ID
        await rideRef.update({'id': rideRef.id});

        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ride: ${e.toString()}'),
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
        title: Text('Offer a Ride'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 24),

              // Origin field
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: 'Origin',
                  hintText: 'Where are you starting from?',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an origin';
                  }
                  return null;
                },
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

              // Destination field
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Where are you going?',
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

              // Date and time selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
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
                            Text(DateFormat('MMM dd, yyyy')
                                .format(_departureDate)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time),
                            SizedBox(width: 8),
                            Text(_departureTime.format(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Available seats
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Available Seats',
                  prefixIcon: Icon(Icons.event_seat),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _availableSeats.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter available seats';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _availableSeats = int.tryParse(value) ?? _availableSeats;
                  });
                },
              ),
              SizedBox(height: 16),

              // Notes
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional information',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _notes = value;
                  });
                },
              ),
              SizedBox(height: 24),

              // Submit button
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Create Ride',
                      onPressed: _createRide,
                      icon: Icons.add,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
