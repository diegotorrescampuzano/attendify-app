// services/home_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  // Obtiene los datos de la escuela
  static Future<Map<String, dynamic>> getSchoolData() async {
    final doc = await FirebaseFirestore.instance.collection('schools').doc('school_001').get();
    if (doc.exists) {
      final data = doc.data()!;
      return {
        'name': data['name'] ?? '',
        'logo': data['logo'] ?? '',
      };
    }
    return {
      'name': 'Nombre no disponible',
      'logo': '',
    };
  }
}
