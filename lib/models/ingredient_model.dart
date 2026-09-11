import 'package:cloud_firestore/cloud_firestore.dart';

class Ingredient {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final DateTime lastUpdated;

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.lastUpdated,
  });

  factory Ingredient.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final lastUpdated = data['lastUpdated'];

    return Ingredient(
      id: document.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] as String? ?? '',
      lastUpdated: lastUpdated is Timestamp
          ? lastUpdated.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
