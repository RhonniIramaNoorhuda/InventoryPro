import 'package:flutter/material.dart';

import '../models/ingredient_model.dart';
import '../services/firebase_service.dart';

class AddIngredientScreen extends StatefulWidget {
  AddIngredientScreen({
    super.key,
    this.ingredient,
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService();

  final Ingredient? ingredient;
  final FirestoreService _firestoreService;

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  var _isSaving = false;

  bool get _isEditing => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    final ingredient = widget.ingredient;
    _nameController = TextEditingController(text: ingredient?.name ?? '');
    _categoryController = TextEditingController(
      text: ingredient?.category ?? '',
    );
    _quantityController = TextEditingController(
      text: ingredient == null ? '' : _formatQuantity(ingredient.quantity),
    );
    _unitController = TextEditingController(text: ingredient?.unit ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final quantity = double.parse(_quantityController.text.trim());
    final ingredient = Ingredient(
      id: widget.ingredient?.id ?? '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      quantity: quantity,
      unit: _unitController.text.trim(),
      lastUpdated: DateTime.now(),
    );

    try {
      if (_isEditing) {
        await widget._firestoreService.updateIngredient(ingredient);
      } else {
        await widget._firestoreService.createIngredient(ingredient);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan bahan: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Bahan' : 'Tambah Bahan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bahan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama bahan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kategori wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Stok',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final quantity = double.tryParse(value?.trim() ?? '');
                    if (quantity == null) {
                      return 'Jumlah stok harus berupa angka';
                    }
                    if (quantity < 0) {
                      return 'Jumlah stok tidak boleh negatif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Satuan wajib diisi';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _isSaving ? null : _saveIngredient(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveIngredient,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatQuantity(double quantity) {
  return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
}
