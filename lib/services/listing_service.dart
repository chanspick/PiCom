
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a stream of listings with optional filtering and sorting
  Stream<List<Listing>> getListings({String? category, String? sortBy}) {
    Query query = _firestore.collection('listings').where('status', isEqualTo: 'available');

    // Apply category filter
    if (category != null && category != 'All') {
      query = query.where('partCategory', isEqualTo: category);
    }

    // Apply sorting
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
      default: // Default sort by latest
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
    });
  }

  // Get a stream of the latest available listings for the home screen
  Stream<List<Listing>> getLatestListings({int limit = 10}) {
    return _firestore
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
    });
  }

  // Get a stream for a single listing
  Stream<Listing> getListing(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((doc) => Listing.fromFirestore(doc));
  }

  // Get a user's sales history
  Stream<List<Listing>> getMySalesHistory(String sellerId) {
    return _firestore
        .collection('listings')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList());
  }

  // Get a user's purchase history
  Stream<List<Listing>> getMyPurchaseHistory(String buyerId) {
    return _firestore
        .collection('listings')
        .where('status', isEqualTo: 'sold') // Only show completed purchases
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('soldAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList());
  }
}
