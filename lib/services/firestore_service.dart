import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    required String provider,
  }) async {
    await _db.collection('users').doc(uid).set(
      {
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'provider': provider,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(), // 최초 생성 시에만 설정
      },
      SetOptions(merge: true), // 기존 필드는 유지하고 새로운 필드만 추가/업데이트
    );
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // 사용자 문서 가져오기
  Future<DocumentSnapshot?> getUser(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      // TODO: 에러 처리
      return null;
    }
  }
}
