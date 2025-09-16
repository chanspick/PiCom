import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// 사용자 정보 생성 또는 업데이트
Future<void> createOrUpdateUser({
required String uid,
required String email,
required String name,
String? photoUrl,
required String provider,
}) async {
try {
await _firestore.collection('users').doc(uid).set({
'uid': uid,
'email': email,
'name': name,
'photoUrl': photoUrl,
'provider': provider,
'createdAt': FieldValue.serverTimestamp(),
'lastLoginAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
} catch (e) {
print('사용자 데이터 저장 실패: $e');
throw e;
}
}

// 사용자 정보 조회
Future<Map<String, dynamic>?> getUser(String uid) async {
try {
final doc = await _firestore.collection('users').doc(uid).get();
return doc.exists ? doc.data() : null;
} catch (e) {
print('사용자 데이터 조회 실패: $e');
return null;
}
}

// 사용자 정보 삭제
Future<void> deleteUser(String uid) async {
try {
await _firestore.collection('users').doc(uid).delete();
} catch (e) {
print('사용자 데이터 삭제 실패: $e');
throw e;
}
}

// 사용자 프로필 업데이트
Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
try {
await _firestore.collection('users').doc(uid).update(data);
} catch (e) {
print('사용자 프로필 업데이트 실패: $e');
throw e;
}
}



// 상품 목록 조회 (실시간 스트림)
Stream<QuerySnapshot> getProductsStream() {
return _firestore
    .collection('products')
    .orderBy('createdAt', descending: true)
    .snapshots();
}

// 특정 상품 조회
Future<DocumentSnapshot> getProduct(String productId) async {
return await _firestore.collection('products').doc(productId).get();
}

// 상품 삭제
Future<void> deleteProduct(String productId) async {
try {
await _firestore.collection('products').doc(productId).delete();
} catch (e) {
print('상품 삭제 실패: $e');
throw e;
}
}


}
