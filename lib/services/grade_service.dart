import 'package:cloud_firestore/cloud_firestore.dart';

class GradeService {
  // Retrieves the list of grades associated with a specific educational level
  static Future<List<Map<String, dynamic>>> getGradesForLevel(String educationalLevelId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('grades')
        .where(
      'educationalLevelId',
      isEqualTo: FirebaseFirestore.instance.doc('educationalLevels/$educationalLevelId'),
    )
        .get();

    // Map each document to a usable Map structure
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'description': data['description'],
        'homerooms': data['homerooms'], // List of references to homerooms
        'educationalLevelId': data['educationalLevelId']
      };
    }).toList();
  }
}
