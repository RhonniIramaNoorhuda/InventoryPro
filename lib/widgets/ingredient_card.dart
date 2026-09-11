import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';

class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key, 
    required this.ingredient,
    this.onEdit,
    this.onDelete,
  });

  final Ingredient ingredient;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    // Menentukan apakah stok sudah menipis (kurang dari 5)
    final isLowStock = ingredient.quantity < 5;
    
    // Menghilangkan angka desimal .0 jika bilangannya bulat
    final quantity = ingredient.quantity % 1 == 0
        ? ingredient.quantity.toInt().toString()
        : ingredient.quantity.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          ingredient.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(ingredient.category),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$quantity ${ingredient.unit}',
              style: TextStyle(
                color: isLowStock ? Colors.red : null,
                fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            // Tombol Edit yang memicu pop-up form di DashboardScreen
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit, 
            ),
            // Tombol Hapus yang memicu pop-up konfirmasi di DashboardScreen
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete, 
            ),
          ],
        ),
      ),
    );
  }
}