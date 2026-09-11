import "package:cloud_firestore/cloud_firestore.dart";

class TransactionLog {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final String type;
  final double amount;
  final DateTime timestamp;

  const TransactionLog({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.type,
    required this.amount,
    required this.timestamp,
  });

  factory TransactionLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data["timestamp"];

    return TransactionLog(
      id: document.id,
      ingredientId: data["ingredientId"] as String? ?? "",
      ingredientName: data["ingredientName"] as String? ?? "",
      type: data["type"] as String? ?? "",
      amount: (data["amount"] as num?)?.toDouble() ?? 0.0,
      timestamp: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "ingredientId": ingredientId,
      "ingredientName": ingredientName,
      "type": type,
      "amount": amount,
      "timestamp": Timestamp.fromDate(timestamp),
    };
  }
}
