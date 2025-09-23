import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SearchService {
  Future<List<Product>> searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) {
      return [];
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User is not authenticated. Aborting search.");
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'User is not signed in.',
        );
      }

      // 토큰을 가져와서 payload를 디코딩하고 출력합니다.
      final idTokenString = await currentUser.getIdToken(true);
      print("Successfully refreshed auth token.");

      if (idTokenString == null) {
        print("Failed to get ID token string.");
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'Failed to retrieve a valid ID token.',
        );
      }

      final parts = idTokenString.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        print('Decoded token payload: $decoded');
      }

      // 'searchProducts' 이름의 Cloud Function을 호출합니다.
      final FirebaseFunctions functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final HttpsCallable callable = functions.httpsCallable('searchProducts');
      final result = await callable.call<List<dynamic>>({'keyword': keyword});

      print('Algolia raw result data: ${result.data}');

      final products = result.data.map((hit) {
        final data = hit as Map<String, dynamic>;
        return Product(
          id: data['objectID'] ?? '',
          name: data['name'] ?? '',
          brand: data['brand'] ?? '',
          modelCode: data['modelCode'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          lastTradedPrice: (data['lastTradedPrice'] as num?)?.toDouble() ?? 0.0,
          priceHistory: [],
        );
      }).toList();

      return products;
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function 호출 실패: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      print('상품 검색 중 알 수 없는 에러: $e');
      return [];
    }
  }
}
