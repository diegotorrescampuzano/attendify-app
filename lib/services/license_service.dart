import 'package:cloud_firestore/cloud_firestore.dart';

class LicenseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get the current license data for the school
  static Future<Map<String, dynamic>?> getLicense() async {
    try {
      final doc = await _db.collection('licenses').doc('school_001').get();
      if (!doc.exists) {
        print('[LicenseService] No license document found.');
        return null;
      }
      print('[LicenseService] License data: ${doc.data()}');
      return doc.data();
    } catch (e) {
      print('[LicenseService] Error getting license: $e');
      return null;
    }
  }

  /// Check if the license is valid (active and not expired)
  static Future<bool> isLicenseValid() async {
    final license = await getLicense();
    if (license == null) {
      print('[LicenseService] No license data.');
      return false;
    }
    final bool active = license['active'] ?? false;
    final Timestamp? expiryTimestamp = license['expiryDate'];
    if (!active) {
      print('[LicenseService] License is not active.');
      return false;
    }
    final expiryDate = expiryTimestamp?.toDate();
    final now = DateTime.now();
    if (expiryDate == null || now.isAfter(expiryDate)) {
      print('[LicenseService] License is expired.');
      return false;
    }
    print('[LicenseService] License is valid.');
    return true;
  }

  /// Check if the license is about to expire (within warnDaysBeforeExpiry)
  static Future<bool> isLicenseAboutToExpire() async {
    final license = await getLicense();
    if (license == null) return false;
    final Timestamp? expiryTimestamp = license['expiryDate'];
    final int? warnDays = license['warnDaysBeforeExpiry'];
    if (expiryTimestamp == null || warnDays == null) return false;
    final expiryDate = expiryTimestamp.toDate();
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    print('[LicenseService] Days until expiry: $difference');
    return difference <= warnDays && difference >= 0;
  }

  /// Get the latest version from the license document
  static Future<String?> getLatestVersion() async {
    final license = await getLicense();
    return license?['version'] as String?;
  }
}
