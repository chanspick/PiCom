
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:picom/models/part_model.dart';

class PartName extends StatelessWidget {
  final String partId;

  const PartName({super.key, required this.partId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('parts').doc(partId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('부품 정보 없음', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
        }
        final part = Part.fromFirestore(snapshot.data!);
        return Text(
          part.modelName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
