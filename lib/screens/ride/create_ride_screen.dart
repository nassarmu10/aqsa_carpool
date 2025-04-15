// lib/screens/ride/create_ride_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../models/ride_model.dart';

class CreateRideScreen extends StatefulWidget {
  @override
  _CreateRideScreenState createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _origin = '';
  String _destination = 'Al-Aqsa Mosque';
  DateTime _departureDate = DateTime.now();
  TimeOfDay _departureTime = TimeOfDay.now();
  int _availableSeats = 3;
  // double _price = 0.0;
  String? _notes;
  bool _isLoading = false;

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

  Future<void> _createRide() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Get user name from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        String driverName = userDoc.exists 
            ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
            : 'Unknown';

        // Create ride document
        DocumentReference rideRef = await _firestore.collection('rides').add({
          'driverId': currentUser.uid,
          'driverName': driverName,
          'origin': _origin,
          'destination': _destination,
          'departureTime': Timestamp.fromDate(_combineDateTime()),
          'availableSeats': _availableSeats,
          // 'price': _price,
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
                decoration: InputDecoration(
                  labelText: 'Origin',
                  hintText: 'Where are you starting from?',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an origin';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _origin = value;
                  });
                },
              ),
              SizedBox(height: 16),
              
              // Destination field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Where are you going?',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                initialValue: _destination,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a destination';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _destination = value;
                  });
                },
              ),
              SizedBox(height: 16),
              
              // Date and time selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
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
                            Text(DateFormat('MMM dd, yyyy').format(_departureDate)),
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
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
              
              // Price
              // TextFormField(
              //   decoration: InputDecoration(
              //     labelText: 'Price (ILS)',
              //     prefixIcon: Icon(Icons.attach_money),
              //     border: OutlineInputBorder(),
              //   ),
              //   keyboardType: TextInputType.numberWithOptions(decimal: true),
              //   initialValue: _price.toString(),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter a price';
              //     }
              //     if (double.tryParse(value) == null) {
              //       return 'Please enter a valid price';
              //     }
              //     return null;
              //   },
              //   onChanged: (value) {
              //     setState(() {
              //       _price = double.tryParse(value) ?? _price;
              //     });
              //   },
              // ),
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
