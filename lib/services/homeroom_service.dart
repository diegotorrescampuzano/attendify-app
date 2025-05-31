import 'package:cloud_firestore/cloud_firestore.dart';

class HomeroomService {
  // Existing method
  static Future<List<Map<String, dynamic>>> getHomeroomsFromReferences(List<dynamic> references) async {
    List<Map<String, dynamic>> homerooms = [];

    for (var ref in references) {
      if (ref is DocumentReference) {
        final snapshot = await ref.get();
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          homerooms.add({
            'id': snapshot.id,
            'name': data['name'],
            'description': data['description'],
            'students': data['students'], // Lista de estudiantes
            'subjects': data['subjects'], // Lista de asignaturas
          });
        }
      }
    }

    return homerooms;
  }

  // New method to fetch students by homeroom reference
  static Future<List<Map<String, dynamic>>> getStudentsFromHomeroom(DocumentReference homeroomRef) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('homeroom', isEqualTo: homeroomRef)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching students by homeroom: $e');
      return [];
    }
  }
}
