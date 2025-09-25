import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this import
import 'dart:math'; // Add this import
import '../../models/part_model.dart';


class PartDetailScreen extends StatelessWidget {
  final String partId;

  const PartDetailScreen({super.key, required this.partId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 상세 정보'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('parts').doc(partId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('부품을 찾을 수 없습니다.'));
          }

          final part = Part.fromFirestore(snapshot.data!); // Use the Part model

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Removed image display section as Part model does not have imageUrl
                const SizedBox(height: 20),
                Text(
                  part.modelName, // Changed from part.name to part.modelName
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '브랜드: ${part.brand}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '카테고리: ${part.category.name}', // Display enum name
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                // Removed "주요 사양" section as Part model does not have specs
                // If detailed specs are needed for a Part, they should be added to the Part model.
              ],
            ),
          );
        },
      ),
    );
  }
}
