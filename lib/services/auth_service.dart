import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in anonymously and save user name
  Future<User?> signInAnonymously(String name) async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      
      if (user != null) {
        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user name from Firestore
  Future<String?> getUserName(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['name'];
      }
      return null;
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }
}
