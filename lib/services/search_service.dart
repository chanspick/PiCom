import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/base_part_model.dart';

class SearchService {
  // === 수정: 반환 타입을 List<BasePart>로 변경 ===
  Future<List<BasePart>> searchProducts(String keyword) async {
    print("--- SearchService: searchProducts initiated with keyword: '$keyword' ---");
    if (keyword.trim().isEmpty) {
      print("--- SearchService: Keyword is empty. Returning empty list. ---");
      return [];
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("--- SearchService: ERROR - User is not authenticated. ---");
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'User is not signed in.',
        );
      }

      print("--- SearchService: User is authenticated: ${currentUser.uid} ---");
      final FirebaseFunctions functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final HttpsCallable callable = functions.httpsCallable('searchProducts');
      print("--- SearchService: Calling Cloud Function 'searchProducts' with keyword: '$keyword' ---");
      final result = await callable.call<List>({'keyword': keyword});
      print("--- SearchService: Cloud Function call successful. ---");

      if (result.data == null) {
        print("--- SearchService: WARNING - Cloud function returned null data. ---");
        return [];
      }

      print("--- SearchService: Received ${result.data.length} hits from Algolia. ---");
      print("--- SearchService: Raw data preview: ${result.data.toString().substring(0, 500)}...");

      // === 수정: List<BasePart>로 변경 ===
      final List<BasePart> parts = [];
      for (final hit in result.data) {
        try {
          final data = _castMap(hit as Map);
          // === 수정: BasePart.fromMap 사용 ===
          parts.add(BasePart.fromMap(data));
        } catch (e) {
          print("--- SearchService: ERROR - Failed to parse a search result, skipping. Error: $e ---");
          print("--- SearchService: Problematic data: $hit ---");
        }
      }
      print("--- SearchService: Successfully parsed ${parts.length} parts. ---");
      return parts;
    } on FirebaseFunctionsException catch (e) {
      print("--- SearchService: FATAL - Cloud Function Exception: ${e.code} - ${e.message} ---");
      return [];
    } catch (e) {
      print("--- SearchService: FATAL - Unknown Exception: $e ---");
      return [];
    }
  }

  Map<String, dynamic> _castMap(Map map) {
    final newMap = <String, dynamic>{};
    map.forEach((key, value) {
      if (key is String) {
        if (value is Map) {
          newMap[key] = _castMap(value);
        } else if (value is List) {
          newMap[key] = _castList(value);
        } else {
          newMap[key] = value;
        }
      }
    });
    return newMap;
  }

  List _castList(List list) {
    final newList = [];
    for (final item in list) {
      if (item is Map) {
        newList.add(_castMap(item));
      } else if (item is List) {
        newList.add(_castList(item));
      } else {
        newList.add(item);
      }
    }
    return newList;
  }
}