// logic/km_detail_logic.dart
import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../models/km_entry.dart';

class KmDetailLogic {
  final KmController controller;
  final DateTime selectedDate;
  final VoidCallback onClose;
  final BuildContext context;

  KmDetailLogic({
    required this.controller,
    required this.selectedDate,
    required this.onClose,
    required this.context,
  });

  // Data operations
  List<KmEntry> getEntriesForDate() {
    return controller.getEntriesForDate(selectedDate);
  }

  // Entry management
  Future<void> addOrUpdateEntry(KmEntry? existingEntry, KmEntry newEntry) async {
    if (existingEntry != null) {
      final globalIndex = controller.entries.indexOf(existingEntry);
      if (globalIndex >= 0) {
        await controller.updateEntry(globalIndex, newEntry);
        _showSuccessMessage('Entry aggiornata con successo');
      }
    } else {
      await controller.addEntry(newEntry);
      _showSuccessMessage('Entry aggiunta con successo');
    }
  }

  Future<void> deleteEntry(KmEntry entry) async {
    final globalIndex = controller.entries.indexOf(entry);
    if (globalIndex >= 0) {
      await controller.deleteEntry(globalIndex);
      _showSuccessMessage('Entry eliminata');
    }
  }

  // Dialog management
  void showAddEditDialog({KmEntry? entry, int? index, required VoidCallback onRefresh}) {
    showDialog(
      context: context,
      builder: (context) => AddEditEntryDialog(
        entry: entry,
        selectedDate: selectedDate,
        onSave: (newEntry) async {
          await addOrUpdateEntry(entry, newEntry);
          onRefresh();
        },
      ),
    ).then((_) => onRefresh());
  }

  void showDeleteConfirmationDialog(KmEntry entry, VoidCallback onRefresh) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare l\'entry ${entry.category.displayName} '
          'di ${entry.kilometers} km?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await deleteEntry(entry);
              onRefresh();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  // Utility methods
  String formatDate() {
    const weekdays = [
      'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 
      'Venerdì', 'Sabato', 'Domenica'
    ];
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${weekdays[selectedDate.weekday - 1]} ${selectedDate.day} ${months[selectedDate.month - 1]}';
  }

  Color getCategoryColor(KmCategory category) {
    switch (category) {
      case KmCategory.personal:
        return Colors.blue;
      case KmCategory.work:
        return Colors.orange;
    }
  }

  IconData getCategoryIcon(KmCategory category) {
    switch (category) {
      case KmCategory.personal:
        return Icons.person;
      case KmCategory.work:
        return Icons.work;
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Separate dialog component
class AddEditEntryDialog extends StatefulWidget {
  final KmEntry? entry;
  final DateTime selectedDate;
  final Function(KmEntry) onSave;

  const AddEditEntryDialog({
    super.key,
    this.entry,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<AddEditEntryDialog> createState() => _AddEditEntryDialogState();
}

class _AddEditEntryDialogState extends State<AddEditEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  late KmCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.entry?.category ?? KmCategory.personal;
    _kmController.text = widget.entry?.kilometers.toString() ?? '';
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final entry = KmEntry(
        date: widget.selectedDate,
        kilometers: double.parse(_kmController.text),
        category: _selectedCategory,
      );
      widget.onSave(entry);
      Navigator.of(context).pop();
    }
  }

  Color _getCategoryColor(KmCategory category) {
    switch (category) {
      case KmCategory.personal:
        return Colors.blue;
      case KmCategory.work:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.entry != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifica Viaggio' : 'Nuovo Viaggio'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _kmController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Chilometri',
                border: OutlineInputBorder(),
                suffixText: 'km',
                prefixIcon: Icon(Icons.route),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci i chilometri';
                }
                final km = double.tryParse(value);
                if (km == null || km <= 0) {
                  return 'Inserisci un valore valido';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Text(
              'Categoria:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: KmCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                final categoryColor = _getCategoryColor(category);
                
                return FilterChip(
                  selected: isSelected,
                  label: Text(category.displayName),
                  avatar: Icon(
                    isSelected ? Icons.check : Icons.circle,
                    size: 16,
                    color: isSelected ? Colors.white : categoryColor,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: categoryColor,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Salva' : 'Aggiungi'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }
}