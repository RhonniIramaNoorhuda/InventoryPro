import "package:cloud_firestore/cloud_firestore.dart";

import "../models/ingredient_model.dart";
import "../models/history_log_model.dart";
import "../models/transaction_log_model.dart";

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ingredientsCollection =>
      _firestore.collection("ingredients");

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection("transactions");

  CollectionReference<Map<String, dynamic>> get _historyCollection =>
      _firestore.collection("history");

  Future<String> createIngredient(Ingredient ingredient) async {
    final document = await _ingredientsCollection.add(ingredient.toFirestore());

    final history = HistoryLog(
      id: "",
      aksi: "Tambah",
      namaBahan: ingredient.name,
      jumlah: ingredient.quantity,
      unit: ingredient.unit, // <-- Tambahkan unit saat create
      timestamp: DateTime.now(),
    );

    await _historyCollection.add(history.toFirestore());

    return document.id;
  }

  Stream<List<Ingredient>> readIngredients() {
    return _ingredientsCollection
        .orderBy("lastUpdated", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => Ingredient.fromFirestore(document))
              .toList(),
        );
  }

  Stream<List<TransactionLog>> readTransactions() {
    return _transactionsCollection
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => TransactionLog.fromFirestore(document))
              .toList(),
        );
  }

  Stream<List<HistoryLog>> readHistory() {
    return _historyCollection
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => HistoryLog.fromFirestore(document))
              .toList(),
        );
  }

  Future<void> addTransactionLog({
    required String ingredientId,
    required String ingredientName,
    required String type,
    required double amount,
  }) async {
    final transaction = TransactionLog(
      id: "",
      ingredientId: ingredientId,
      ingredientName: ingredientName,
      type: type,
      amount: amount,
      timestamp: DateTime.now(),
    );

    await _transactionsCollection.add(transaction.toFirestore());
  }

  Future<Ingredient?> readIngredientById(String id) async {
    final document = await _ingredientsCollection.doc(id).get();

    if (!document.exists) {
      return null;
    }

    return Ingredient.fromFirestore(document);
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    await _ingredientsCollection
        .doc(ingredient.id)
        .update(ingredient.toFirestore());

    final history = HistoryLog(
      id: "",
      aksi: "Edit",
      namaBahan: ingredient.name,
      jumlah: ingredient.quantity,
      unit: ingredient.unit, // <-- Tambahkan unit saat update
      timestamp: DateTime.now(),
    );

    await _historyCollection.add(history.toFirestore());
  }

  Future<void> deleteIngredient(String id) async {
    final document = await _ingredientsCollection.doc(id).get();

    if (document.exists) {
      final ingredient = Ingredient.fromFirestore(document);

      await _ingredientsCollection.doc(id).delete();

      final history = HistoryLog(
        id: "",
        aksi: "Hapus",
        namaBahan: ingredient.name,
        jumlah: ingredient.quantity,
        unit: ingredient.unit, // <-- Tambahkan unit saat delete
        timestamp: DateTime.now(),
      );

      await _historyCollection.add(history.toFirestore());
    }
  }
}