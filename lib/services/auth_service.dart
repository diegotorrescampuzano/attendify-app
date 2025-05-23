import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns null if login is successful, otherwise returns an error message
  static Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Login OK
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (_) {
      return 'Unexpected error';
    }
  }
}
