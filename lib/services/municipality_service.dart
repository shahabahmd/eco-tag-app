import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles all Firestore reads/writes related to admin municipality selection.
class MunicipalityService {
  static final _db = FirebaseFirestore.instance;

  /// Returns the municipality status for [uid].
  /// Returns a map with keys: 'municipality' (String?) and 'municipalityLocked' (bool).
  static Future<Map<String, dynamic>> getMunicipalityStatus(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return {'municipality': null, 'municipalityLocked': false};
    final data = doc.data()!;
    return {
      'municipality': data['municipality'] as String?,
      'municipalityLocked': (data['municipalityLocked'] as bool?) ?? false,
    };
  }

  /// Returns true if the municipality is already locked for the current user.
  static Future<bool> isLocked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final status = await getMunicipalityStatus(uid);
    return status['municipalityLocked'] == true;
  }

  /// Saves [municipality] to Firestore for [uid] and sets municipalityLocked = true.
  static Future<void> saveMunicipality(String uid, String email, String municipality) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'role': 'admin',
      'municipality': municipality,
      'municipalityLocked': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
