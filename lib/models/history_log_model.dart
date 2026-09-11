import "package:cloud_firestore/cloud_firestore.dart";

class HistoryLog {
  final String id;
  final String aksi;
  final String namaBahan;
  final double jumlah;
  final String unit; // <-- TAMBAHKAN INI
  final DateTime timestamp;

  const HistoryLog({
    required this.id,
    required this.aksi,
    required this.namaBahan,
    required this.jumlah,
    required this.unit, // <-- TAMBAHKAN INI
    required this.timestamp,
  });

  factory HistoryLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data["timestamp"];

    return HistoryLog(
      id: document.id,
      aksi: data["aksi"] as String? ?? "",
      namaBahan: data["namaBahan"] as String? ?? "",
      jumlah: (data["jumlah"] as num?)?.toDouble() ?? 0.0,
      unit: data["unit"] as String? ?? "", // <-- Ambil unit dari Firestore
      timestamp: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "aksi": aksi,
      "namaBahan": namaBahan,
      "jumlah": jumlah,
      "unit": unit, // <-- Simpan unit ke Firestore
      "timestamp": FieldValue.serverTimestamp(),
    };
  }
}