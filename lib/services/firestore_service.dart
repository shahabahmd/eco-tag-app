import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> addReport({
    required String type,
    required String description,
    required String imageUrl,
    required double lat,
    required double lng,
  }) async {
    await _db.collection('reports').add({
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'lat': lat,
      'lng': lng,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
