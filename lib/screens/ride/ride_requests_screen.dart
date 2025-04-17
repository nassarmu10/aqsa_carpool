// lib/screens/ride/ride_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_button.dart';

class RideRequestsScreen extends StatefulWidget {
  final String rideId;
  
  const RideRequestsScreen({
    Key? key,
    required this.rideId,
  }) : super(key: key);

  @override
  _RideRequestsScreenState createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _rideData;
  List<Map<String, dynamic>> _requesters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get ride data
      DocumentSnapshot rideDoc = await _firestore
          .collection('rides')
          .doc(widget.rideId)
          .get();

      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;
      List<String> pendingRequests = List<String>.from(rideData['pendingRequests'] ?? []);
      
      List<Map<String, dynamic>> requesters = [];
      
      // Get user data for each requester
      for (String userId in pendingRequests) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
            
        if (userDoc.exists) {
          requesters.add({
            'id': userId,
            ...userDoc.data() as Map<String, dynamic>,
          });
        }
      }

      setState(() {
        _rideData = rideData;
        _requesters = requesters;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading requests: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading requests: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveRequest(String userId) async {
    try {
      // Update ride document
      await _firestore.collection('rides').doc(widget.rideId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
        'passengers': FieldValue.arrayUnion([userId]),
        'availableSeats': FieldValue.increment(-1),
      });
      
      // Reload data
      await _loadRequests();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error approving request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineRequest(String userId) async {
    try {
      // Update ride document
      await _firestore.collection('rides').doc(widget.rideId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
      });
      
      // Reload data
      await _loadRequests();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request declined'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error declining request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Ride Requests')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rideData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ride Requests')),
        body: Center(
          child: Text('Ride not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ride Requests'),
      ),
      body: _requesters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _requesters.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> requester = _requesters[index];
                
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    requester['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (requester['phone'] != null)
                                    Text(
                                      requester['phone'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _declineRequest(requester['id']),
                              child: Text('Decline'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _rideData!['availableSeats'] > 0
                                  ? () => _approveRequest(requester['id'])
                                  : null,
                              child: Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
