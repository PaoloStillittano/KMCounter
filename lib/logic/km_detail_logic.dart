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
  Future<void> addOrUpdateEntry(
      KmEntry? existingEntry, KmEntry newEntry) async {
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
    // Non serve più chiamare onRefresh, il calendario si aggiornerà automaticamente
  }

  Future<void> deleteEntry(KmEntry entry) async {
    final globalIndex = controller.entries.indexOf(entry);
    if (globalIndex >= 0) {
      await controller.deleteEntry(globalIndex);
      _showSuccessMessage('Entry eliminata');
    }
    // Non serve più chiamare onRefresh, il calendario si aggiornerà automaticamente
  }

  // Dialog management - versione semplificata senza onRefresh
  void showAddEditDialog({KmEntry? entry, int? index}) {
    showDialog(
      context: context,
      builder: (context) => AddEditEntryDialog(
        entry: entry,
        selectedDate: selectedDate,
        onSave: (newEntry) async {
          await addOrUpdateEntry(entry, newEntry);
        },
      ),
    );
  }

  void showDeleteConfirmationDialog(KmEntry entry) {
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
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
      'Domenica'
    ];
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre'
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
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    // Calcola l'altezza massima disponibile per il dialog
    final maxHeight =
        screenHeight - keyboardHeight - 100; // 100 per margini di sicurezza

    return AlertDialog(
      title: null,
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 400, // Larghezza massima per schermi grandi
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section - Altezza fissa
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: isDark
                      ? Colors.white.withAlpha(38)
                      : Colors.blue.withAlpha(115),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add_road,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Modifica Viaggio' : 'Nuovo Viaggio',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Aggiorna i dettagli del viaggio'
                                : 'Aggiungi un nuovo viaggio',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      tooltip: 'Chiudi',
                    ),
                  ],
                ),
              ),

              // Form Content - Scrollabile se necessario
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _kmController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Chilometri',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            border: const OutlineInputBorder(),
                            suffixText: 'km',
                            prefixIcon: const Icon(Icons.route),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withAlpha(38)
                                    : Colors.black.withAlpha(130),
                                width: 2.0,
                              ),
                            ),
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
                          showCursor: false,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Categoria:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: KmCategory.values.map((category) {
                            final isSelected = _selectedCategory == category;
                            final categoryColor = _getCategoryColor(category);

                            return FilterChip(
                              selected: isSelected,
                              label: Text(
                                category.displayName,
                                style: TextStyle(
                                  color: isSelected ? categoryColor : null,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : null,
                                ),
                              ),
                              avatar: Icon(
                                isSelected ? Icons.check : Icons.circle,
                                size: 16,
                                color: categoryColor,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              selectedColor: isDark
                                  ? Colors.white.withAlpha(20)
                                  : Colors.black.withAlpha(20),
                              backgroundColor: isDark
                                  ? Colors.white.withAlpha(20)
                                  : Colors.black.withAlpha(20),
                              checkmarkColor: categoryColor,
                              side: BorderSide(
                                color: categoryColor,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              
                            );
                          }).toList(),
                        ),
                        // Aggiungi un po' di spazio extra per evitare che il contenuto sia troppo vicino ai bottoni
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annulla',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withAlpha(38)
                    : Colors.black.withAlpha(130),
                width: 2,
              ),
            ),
          ),
          child: Text(
            isEditing ? 'Salva' : 'Aggiungi',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }
}
