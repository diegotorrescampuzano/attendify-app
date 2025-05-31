import 'package:cloud_firestore/cloud_firestore.dart';

class HomeroomService {
  // Recibe una lista de DocumentReference y retorna sus datos
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
            'students': data['students'], // Lista de estudiantes'
            'subjects': data['subjects'], // Lista de asignaturas
            // puedes agregar más campos según tu estructura
          });
        }
      }
    }

    return homerooms;
  }
}
