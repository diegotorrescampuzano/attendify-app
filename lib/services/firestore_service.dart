import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get the current user's profile data (name, role, email)
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = AuthService.getCurrentUserId();
    print("User ID: $uid");
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      print("User document does not exist.");
      return null;
    }

    print("User data from Firestore: ${doc.data()}");

    // Store in global cache for future access
    AuthService.currentUserData = doc.data();

    return doc.data();
  }
}
