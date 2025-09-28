import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String photoURL;
  final List<String> followers;
  final List<String> following;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.displayName,
    required this.photoURL,
    required this.followers,
    required this.following,
    this.isAdmin = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'] ?? '',
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      isAdmin: data['isAdmin'] ?? false,
    );
  }
}
