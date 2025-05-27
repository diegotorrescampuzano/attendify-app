import 'package:cloud_firestore/cloud_firestore.dart';

// Service class to handle fetching educational levels from Firestore
class EducationalLevelService {

  // Retrieves a list of educational levels associated with a specific campus
  static Future<List<Map<String, dynamic>>> getEducationalLevelsForCampus(String campusId) async {

    // Query the 'educationalLevels' collection where 'campusId' matches the provided document reference
    final snapshot = await FirebaseFirestore.instance
        .collection('educationalLevels')
        .where(
      'campusId',
      isEqualTo: FirebaseFirestore.instance.doc('campuses/$campusId'),
    )
        .get();

    // Convert each document into a Map<String, dynamic> with relevant fields
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,                   // Firestore document ID
        'name': data['name'],          // Name of the educational level
        'description': data['description'],  // Description of the level
        'grades': data['grades'],      // Associated grades
        'campusId': data['campusId']   // Reference to the campus
      };
    }).toList(); // Return the list of mapped educational levels
  }
}
