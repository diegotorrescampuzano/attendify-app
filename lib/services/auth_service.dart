// Import FirebaseAuth to use Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';

/// Our custom authentication service class
class AuthService {
  // Singleton instance of FirebaseAuth
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store user data from Firestore for easy global access
  static Map<String, dynamic>? _currentUserData;

  /// Public getter to access user data (e.g., name, email, refId, etc.)
  static Map<String, dynamic>? get currentUserData => _currentUserData;

  /// Attempts to log in the user with given email and password.
  /// Returns `null` if login is successful.
  /// Returns an error string if login fails.
  static Future<String?> login(String email, String password) async {
    try {
      // Try signing in with email and password
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('[AuthService] Login successful for: $email');
      return null; // Success — return no error
    } on FirebaseAuthException catch (e) {
      // Firebase-specific error occurred
      print('[AuthService] Login failed for $email: ${e.message}');
      return e.message ?? 'Login failed'; // Return specific message or generic
    } catch (e) {
      // Any other unexpected error
      print('[AuthService] Unexpected error during login: $e');
      return 'Unexpected error'; // Fallback error
    }
  }

  /// Logs out the current user from Firebase Authentication.
  /// This will also clear the cached user data.
  static Future<void> logout() async {
    try {
      await _auth.signOut(); // Firebase handles session clearing
      print('[AuthService] User signed out successfully.');
    } catch (e) {
      print('[AuthService] Error during sign out: $e');
    }
    _currentUserData = null; // Clear cached data on logout
  }

  /// Returns the current user ID (UID) if signed in, or null if not signed in.
  static String? getCurrentUserId() {
    final uid = _auth.currentUser?.uid;
    print('[AuthService] getCurrentUserId: $uid');
    return uid;
  }

  /// Used by FirestoreService to cache user profile globally.
  static set currentUserData(Map<String, dynamic>? data) {
    print('[AuthService] Setting current user data: $data');
    _currentUserData = data;
  }
}
