import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/part_model.dart';

/// A widget that fetches and displays information about a Part from its ID.
class PartInfoWidget extends StatelessWidget {
  final String partId;
  final TextStyle? brandStyle;
  final TextStyle? modelNameStyle;
  final CrossAxisAlignment alignment;

  const PartInfoWidget({
    super.key,
    required this.partId,
    this.brandStyle,
    this.modelNameStyle,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('parts').doc(partId).get(),
      builder: (context, snapshot) {
        // While loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }

        // On error or no data
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            'Unknown Part',
            style: modelNameStyle ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }

        // On success
        final part = Part.fromFirestore(snapshot.data!);

        return Column(
          crossAxisAlignment: alignment,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              part.brand,
              style: brandStyle ?? const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              part.modelName,
              style: modelNameStyle ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
