// shared/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  User? get user => _auth.currentUser;
  bool get isAuthenticated => user != null;
  bool get isLoading => _isLoading;

  // Register a new user
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(name);
      }

      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Method renamed from login to signInWithEmailAndPassword
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Method renamed from logout to signOut
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }

  // Added resetPassword method
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
