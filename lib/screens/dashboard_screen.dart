import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/ingredient_model.dart";
import "../services/auth_service.dart";
import "../services/firebase_service.dart";
import "../widgets/animated_widgets.dart";
import "../widgets/ingredient_card.dart";
import "history_screen.dart";
import "login_screen.dart";

// Modern Color Palette
class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color cardShadow = Color(0x1A000000);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
}

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key, FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier("");

  late Stream<List<Ingredient>> _ingredientsStream;

  @override
  void initState() {
    super.initState();
    _ingredientsStream = widget._firestoreService.readIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    try {
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal melakukan logout.")),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Hapus Akun"),
          content: const Text(
            "Apakah Anda yakin ingin menghapus akun? Tindakan ini tidak dapat dibatalkan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Batal"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await context.read<AuthService>().deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  // === FUNGSI CREATE & UPDATE ===
  Future<void> _showIngredientForm([Ingredient? ingredient]) async {
    final isEdit = ingredient != null;
    final nameController = TextEditingController(text: ingredient?.name ?? "");
    final categoryController = TextEditingController(text: ingredient?.category ?? "");
    final quantityController = TextEditingController(text: ingredient?.quantity.toString() ?? "");

    // Daftar pilihan satuan baku untuk inventaris bahan
    final List<String> unitOptions = ['Kg', 'Gram', 'Liter', 'Ml', 'Pcs', 'Ikat', 'Botol', 'Karton'];
    
    // Set nilai default satuan 
    String? selectedUnit = ingredient?.unit;
    if (selectedUnit != null && !unitOptions.contains(selectedUnit)) {
      unitOptions.add(selectedUnit); // Mencegah error jika data lama memakai satuan di luar daftar
    }
    selectedUnit ??= unitOptions.first; // Jika kosong, gunakan opsi pertama

    await showDialog(
      context: context,
      // StatefulBuilder agar state dropdown bisa diperbarui di dalam scope dialog
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(isEdit ? "Edit Bahan" : "Tambah Bahan Baru"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nama Bahan (Cth: Beras)"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: "Kategori (Cth: Pokok)"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Jumlah"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dropdown untuk Satuan
                      Expanded(
                        flex: 2, 
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: const InputDecoration(labelText: "Satuan"),
                          items: unitOptions.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              selectedUnit = newValue; // Memperbarui UI pilihan dropdown
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Batal", style: TextStyle(color: AppColors.textSecondary)),
              ),
              FilledButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final newCategory = categoryController.text.trim();
                  final newQuantity = double.tryParse(quantityController.text.trim()) ?? 0.0;
                  final newUnit = selectedUnit ?? unitOptions.first; // Ambil data dari dropdown

                  if (newName.isEmpty) return;
                  Navigator.pop(dialogContext); // Tutup dialog segera

                  try {
                    if (isEdit) {
                      final updatedIngredient = Ingredient(
                        id: ingredient.id,
                        name: newName,
                        category: newCategory,
                        quantity: newQuantity,
                        unit: newUnit,
                        lastUpdated: DateTime.now(), 
                      );
                      await widget._firestoreService.updateIngredient(updatedIngredient);
                    } else {
                      final newIngredient = Ingredient(
                        id: '', 
                        name: newName,
                        category: newCategory,
                        quantity: newQuantity,
                        unit: newUnit,
                        lastUpdated: DateTime.now(),
                      );
                      await widget._firestoreService.createIngredient(newIngredient);
                    }
                  } catch (e) {
                    if (context.mounted) { // <--- Ubah menjadi context.mounted
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Terjadi kesalahan: $e")),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(isEdit ? "Simpan Perubahan" : "Tambah"),
              ),
            ],
          );
        }
      ),
    );
  }

  // === FUNGSI DELETE ===
  Future<void> _confirmDeleteIngredient(Ingredient ingredient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Bahan?"),
        content: Text("Yakin ingin menghapus '${ingredient.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget._firestoreService.deleteIngredient(ingredient.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menghapus: $e")),
          );
        }
      }
    }
  }

  Widget _buildContent(List<Ingredient> ingredients, {required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 8 : 24,
        isMobile ? 16 : 24,
        isMobile ? 80 : 24, // Beri jarak ekstra di bawah untuk FAB
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, Admin",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 20 : 24,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Kelola inventaris dengan mudah",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isMobile ? 12 : 14,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_2_outlined,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            "Statistik",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          StockSummary(ingredients: ingredients),
          SizedBox(height: isMobile ? 20 : 24),
          if (isMobile) ...[
            Text(
              "Bahan Terbaru",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            CustomSearchBar(
              controller: _searchController,
              notifier: _searchQuery,
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bahan Terbaru",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(
                  width: 300,
                  child: CustomSearchBar(
                    controller: _searchController,
                    notifier: _searchQuery,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: _searchQuery,
            builder: (context, query, child) {
              final filteredIngredients = query.isEmpty
                  ? ingredients
                  : ingredients
                      .where((i) =>
                          i.name.toLowerCase().contains(query.toLowerCase()) ||
                          i.category.toLowerCase().contains(query.toLowerCase()))
                      .toList();

              if (filteredIngredients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_off_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Tidak ada hasil ditemukan",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "\"$query\" tidak cocok dengan bahan apa pun",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                );
              }
              return IngredientList(
                ingredients: filteredIngredients,
                onEdit: _showIngredientForm,
                onDelete: _confirmDeleteIngredient,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF1E293B),
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                "InventoryPro",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              elevation: 0,
            )
          : null,
      drawer: isMobile ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIngredientForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Tambah Bahan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Ingredient>>(
        stream: _ingredientsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final ingredients = snapshot.data ?? [];

          if (isMobile) {
            return _buildContent(ingredients, isMobile: true);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebar(isDrawer: false),
              Expanded(
                child: _buildContent(ingredients, isMobile: false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 260,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(height: isDrawer ? 20 : 40),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "InventoryPro",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              children: [
                SidebarItem(
                  icon: Icons.grid_view_rounded,
                  label: "Dashboard",
                  isActive: true,
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                SidebarItem(
                  icon: Icons.history,
                  label: "Riwayat Transaksi",
                  isActive: false,
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryScreen()),
                    );
                  },
                ),
                const Spacer(),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 8),
                SidebarItem(
                  icon: Icons.logout,
                  label: "Logout",
                  isActive: false,
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    _handleLogout();
                  },
                  isDestructive: false,
                ),
                const SizedBox(height: 8),
                SidebarItem(
                  icon: Icons.delete_forever,
                  label: "Hapus Akun",
                  isActive: false,
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    _confirmDeleteAccount();
                  },
                  isDestructive: true,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-WIDGETS PENDUKUNG TERINTEGRASI
// ==========================================

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color iconColor;

    if (isActive) {
      textColor = Colors.white;
      iconColor = AppColors.primaryLight;
    } else if (isDestructive) {
      textColor = AppColors.error;
      iconColor = AppColors.error;
    } else {
      textColor = const Color(0xFF94A3B8);
      iconColor = const Color(0xFF94A3B8);
    }

    return HoverEffect(
      child: Material(
        color: isActive ? const Color(0xFF334155) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class StockSummary extends StatelessWidget {
  const StockSummary({super.key, required this.ingredients});
  final List<Ingredient> ingredients;

  @override
  Widget build(BuildContext context) {
    final lowStockCount = ingredients.where((i) => i.quantity < 10).length;
    final totalQuantity = ingredients.fold<double>(0, (t, i) => t + i.quantity);
    final categoryCount =
        ingredients.map((i) => i.category).where((c) => c.isNotEmpty).toSet().length;

    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = constraints.maxWidth < 700
          ? constraints.maxWidth
          : (constraints.maxWidth - 32) / 3;

      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          AnimatedFadeSlide(
            index: 0,
            child: SummaryCard(
              width: cardWidth,
              title: "Total Bahan",
              value: ingredients.length.toString(),
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.primary,
            ),
          ),
          AnimatedFadeSlide(
            index: 1,
            child: SummaryCard(
              width: cardWidth,
              title: "Total Stok",
              value: _formatQuantity(totalQuantity),
              icon: Icons.stacked_bar_chart_outlined,
              iconColor: AppColors.secondary,
            ),
          ),
          AnimatedFadeSlide(
            index: 2,
            child: SummaryCard(
              width: cardWidth,
              title: "Stok Menipis",
              value: lowStockCount.toString(),
              icon: Icons.warning_amber_rounded,
              valueColor: lowStockCount > 0 ? AppColors.error : AppColors.textPrimary,
              iconColor: lowStockCount > 0 ? AppColors.error : AppColors.warning,
            ),
          ),
          if (categoryCount > 0)
            AnimatedFadeSlide(
              index: 3,
              child: SummaryCard(
                width: cardWidth,
                title: "Kategori",
                value: categoryCount.toString(),
                icon: Icons.category_outlined,
                iconColor: AppColors.primaryLight,
              ),
            ),
        ],
      );
    });
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
    this.iconColor,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    return HoverEffect(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: effectiveIconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: valueColor ?? AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IngredientList extends StatelessWidget {
  const IngredientList({
    super.key, 
    required this.ingredients,
    required this.onEdit,
    required this.onDelete,
  });
  
  final List<Ingredient> ingredients;
  final Function(Ingredient) onEdit;
  final Function(Ingredient) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ingredients.length,
      itemBuilder: (context, index) => AnimatedFadeSlide(
        index: index,
        child: IngredientCard(
          ingredient: ingredients[index],
          onEdit: () => onEdit(ingredients[index]),
          onDelete: () => onDelete(ingredients[index]),
        ),
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.notifier,
  });

  final TextEditingController controller;
  final ValueNotifier<String> notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (value) => notifier.value = value.trim(),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: "Cari bahan...",
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          suffixIcon: ValueListenableBuilder<String>(
            valueListenable: notifier,
            builder: (context, query, child) {
              if (query.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                onPressed: () {
                  controller.clear();
                  notifier.value = "";
                },
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

String _formatQuantity(double quantity) =>
    quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();