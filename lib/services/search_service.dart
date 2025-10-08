import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/part_model.dart';

class SearchService {
  Future<List<Part>> searchProducts(String keyword) async {
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
      final result = await callable.call<List<dynamic>>({'keyword': keyword});
      print("--- SearchService: Cloud Function call successful. ---");

      if (result.data == null) {
        print("--- SearchService: WARNING - Cloud function returned null data. ---");
        return [];
      }
      print("--- SearchService: Received ${result.data.length} hits from Algolia. ---");
      print("--- SearchService: Raw data preview: ${result.data.toString().substring(0, 500)}...");

      final List<Part> parts = [];
      for (final hit in result.data) {
        try {
          final data = _castMap(hit as Map<Object?, Object?>);
          parts.add(Part.fromMap(data));
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

  Map<String, dynamic> _castMap(Map<Object?, Object?> map) {
    final newMap = <String, dynamic>{};
    map.forEach((key, value) {
      if (key is String) {
        if (value is Map<Object?, Object?>) {
          newMap[key] = _castMap(value);
        } else if (value is List<Object?>) {
          newMap[key] = _castList(value);
        } else {
          newMap[key] = value;
        }
      }
    });
    return newMap;
  }

  List<dynamic> _castList(List<Object?> list) {
    final newList = <dynamic>[];
    for (final item in list) {
      if (item is Map<Object?, Object?>) {
        newList.add(_castMap(item));
      } else if (item is List<Object?>) {
        newList.add(_castList(item));
      } else {
        newList.add(item);
      }
    }
    return newList;
  }
}