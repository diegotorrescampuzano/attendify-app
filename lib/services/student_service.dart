import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  /// Obtiene la lista de estudiantes por referencia a un salón (homeroom)
  static Future<List<Map<String, dynamic>>> getStudentsByHomeroom(DocumentReference homeroomRef) async {
    print("Fetching students for homeroom: $homeroomRef");
    final querySnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('homeroom', isEqualTo: homeroomRef)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        // puedes agregar más campos si es necesario
        // 'ref': doc.reference,
      };
    }).toList();
  }
}
