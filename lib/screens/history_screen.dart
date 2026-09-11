import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/history_log_model.dart";
import "../services/firebase_service.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<HistoryLog>>(
                stream: context.read<FirestoreService>().readHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Gagal memuat riwayat",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Terjadi kesalahan saat memuat data",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Coba Lagi"),
                          ),
                        ],
                      ),
                    );
                  }

                  final history = snapshot.data ?? <HistoryLog>[];

                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(48),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Belum ada riwayat",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Mulai tambahkan bahan untuk melihat riwayat",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: history.length,
                    itemBuilder: (context, index) => HistoryCard(log: history[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Tombol Kembali
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
              tooltip: "Kembali",
            ),
          ),
          // Icon Riwayat
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Riwayat Aksi",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Lihat semua aktivitas terakhir",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.log});

  final HistoryLog log;

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} menit yang lalu";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} jam yang lalu";
    } else {
      return "${diff.inDays} hari yang lalu";
    }
  }

  // Fungsi tambahan agar angka .0 tidak muncul jika bilangan bulat
  String _formatQuantity(double quantity) {
    return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
  }

  Color _getAksiColor(String aksi) {
    switch (aksi) {
      case "Tambah":
        return const Color(0xFF10B981);
      case "Edit":
        return const Color(0xFF3B82F6);
      case "Hapus":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getAksiBackgroundColor(String aksi) {
    switch (aksi) {
      case "Tambah":
        return const Color(0xFF10B981).withValues(alpha: 0.1);
      case "Edit":
        return const Color(0xFF3B82F6).withValues(alpha: 0.1);
      case "Hapus":
        return const Color(0xFFEF4444).withValues(alpha: 0.1);
      default:
        return const Color(0xFF64748B).withValues(alpha: 0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x0D000000),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getAksiBackgroundColor(log.aksi),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getAksiIcon(log.aksi),
            color: _getAksiColor(log.aksi),
          ),
        ),
        title: Text(
          log.namaBahan,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          _formatDateTime(log.timestamp),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _getAksiBackgroundColor(log.aksi),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            // === UPDATE DI SINI: MENAMBAHKAN FORMAT ANGKA & SATUAN ===
            "${_formatQuantity(log.jumlah)} ${log.unit}", 
            style: TextStyle(
              color: _getAksiColor(log.aksi),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAksiIcon(String aksi) {
    switch (aksi) {
      case "Tambah":
        return Icons.add_circle_outline;
      case "Edit":
        return Icons.edit_rounded;
      case "Hapus":
        return Icons.delete_outline_rounded;
      default:
        return Icons.info_outline;
    }
  }
}