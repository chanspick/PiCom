import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart'; // Import the Part model
import '../models/pc_product_model.dart';

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

  // Method to upload parts data from a raw string
  Future<void> uploadPartsData(String partsContent) async {
    final batch = _db.batch();
    final lines = partsContent.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    String currentCategory = '';
    String currentBrand = '';
    final now = DateTime.now();

    for (final line in lines) {
      if (line == 'CPU' || line == '그래픽카드' || line == '메인보드') {
        currentCategory = line;
        currentBrand = ''; // Reset brand when category changes
      } else if (currentCategory.isNotEmpty && (line == 'AMD' || line == '인텔' || line == 'nVidea' || line == 'intel')) {
        currentBrand = line;
      } else if (currentCategory.isNotEmpty && currentBrand.isNotEmpty) {
        // This is a part name
        final String partName = line;
        final String modelCode = partName.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), ''); // Simple derivation

        final part = Part(
          id: _db.collection('parts').doc().id, // Generate a new ID
          category: currentCategory,
          brand: currentBrand,
          name: partName,
          modelCode: modelCode, // Added modelCode
          createdAt: now,
        );
        final partRef = _db.collection('parts').doc(part.id);
        batch.set(partRef, part.toFirestore());
      }
    }

    try {
      await batch.commit();
      print('Parts data uploaded successfully!');
    } catch (e) {
      print('Error uploading parts data: $e');
      rethrow;
    }
  }

  Stream<List<PCProduct>> getPCProducts({String category = 'All', String sortBy = '인기순'}) {
    Query<Map<String, dynamic>> query = _db.collection('pc_products');

    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    switch (sortBy) {
      case '최신순':
        query = query.orderBy('createdAt', descending: true);
        break;
      case '낮은 가격순':
        query = query.orderBy('price', descending: false);
        break;
      case '높은 가격순':
        query = query.orderBy('price', descending: true);
        break;
      case '성능순':
        query = query.orderBy('performanceScore', descending: true);
        break;
      case '인기순':
      default:
        // Assuming 'likes' or a similar field for popularity. If not available, defaults to latest.
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PCProduct.fromFirestore(doc)).toList();
    });
  }
}
