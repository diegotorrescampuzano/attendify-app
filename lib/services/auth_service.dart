// Import FirebaseAuth to use Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';

// Our custom authentication service class
class AuthService {
  // Create a singleton instance of FirebaseAuth
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Attempts to log in the user with given email and password.
  /// Returns `null` if login is successful.
  /// Returns an error string if login fails.
  static Future<String?> login(String email, String password) async {
    try {
      // Try signing in with email and password
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success — return no error
    } on FirebaseAuthException catch (e) {
      // Firebase-specific error occurred
      return e.message ?? 'Login failed'; // Return specific message or generic
    } catch (_) {
      // Any other unexpected error
      return 'Unexpected error'; // Fallback error
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
