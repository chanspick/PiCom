
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/cart_item_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  User? get currentUser => _auth.currentUser;

  // Get cart items stream
  Stream<List<CartItem>> getCartItems() {
    if (currentUser == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('carts')
        .doc(currentUser!.uid)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList();
    });
  }

  // Add to cart using callable function
  Future<void> addToCart(String productId, int quantity) async {
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final HttpsCallable callable = _functions.httpsCallable('addToCart');
    try {
      final result = await callable.call(<String, dynamic>{
        'productId': productId,
        'quantity': quantity,
      });
      print(result.data);
    } on FirebaseFunctionsException catch (e) {
      print('caught firebase functions exception');
      print(e.code);
      print(e.message);
      print(e.details);
    } catch (e) {
      print('caught generic exception');
      print(e);
    }
  }

  // Update quantity using callable function
  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final HttpsCallable callable = _functions.httpsCallable('updateCartItemQuantity');
    try {
      await callable.call(<String, dynamic>{
        'productId': productId,
        'newQuantity': newQuantity,
      });
    } on FirebaseFunctionsException catch (e) {
      print(e.message);
    }
  }

  // Remove from cart using callable function
  Future<void> removeFromCart(String productId) async {
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final HttpsCallable callable = _functions.httpsCallable('removeFromCart');
    try {
      await callable.call(<String, dynamic>{
        'productId': productId,
      });
    } on FirebaseFunctionsException catch (e) {
      print(e.message);
    }
  }
}
