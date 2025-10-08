import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const List<String> _adminEmails = ['wlsrb00g@gmail.com', 'jochanhyeong28@gmail.com'];

  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    required String provider,
  }) async {
    final bool isAdmin = _adminEmails.contains(email);

    await _db.collection('users').doc(uid).set(
      {
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'provider': provider,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': isAdmin,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<DocumentSnapshot?> getUser(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      // Consider logging the error
      return null;
    }
  }
}
