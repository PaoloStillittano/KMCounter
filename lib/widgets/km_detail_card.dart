import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../models/km_entry.dart';

class KmDetailCard extends StatefulWidget {
  final KmController controller;
  final DateTime selectedDate;
  final VoidCallback onClose;

  const KmDetailCard({
    super.key,
    required this.controller,
    required this.selectedDate,
    required this.onClose,
  });

  @override
  State<KmDetailCard> createState() => _KmDetailCardState();
}

class _KmDetailCardState extends State<KmDetailCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  List<KmEntry> _entries = [];
  bool _isAddingNew = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadEntries();
    _animationController.forward();
  }

  void _loadEntries() {
    setState(() {
      _entries = widget.controller.getEntriesForDate(widget.selectedDate);
    });
  }

  void _showAddEditDialog({KmEntry? entry, int? index}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditEntryDialog(
        entry: entry,
        selectedDate: widget.selectedDate,
        onSave: (newEntry) {
          if (entry != null && index != null) {
            // Modifica entry esistente
            final globalIndex = widget.controller.entries.indexOf(entry);
            if (globalIndex >= 0) {
              widget.controller.updateEntry(globalIndex, newEntry);
              _showSuccessMessage('Entry aggiornata con successo');
            }
          } else {
            // Nuova entry
            widget.controller.addEntry(newEntry);
            _showSuccessMessage('Entry aggiunta con successo');
          }
          _loadEntries(); // Ricarica le entries
        },
      ),
    ).then((_) {
      // Assicurati che la UI si aggiorni anche dopo la chiusura del dialog
      _loadEntries();
    });
  }

  void _deleteEntry(KmEntry entry) {
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
            onPressed: () {
              Navigator.of(context).pop();
              final globalIndex = widget.controller.entries.indexOf(entry);
              if (globalIndex >= 0) {
                widget.controller.deleteEntry(globalIndex);
                _showSuccessMessage('Entry eliminata');
                _loadEntries();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    const weekdays = [
      'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 
      'Venerdì', 'Sabato', 'Domenica'
    ];
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  Color _getCategoryColor(KmCategory category) {
    switch (category) {
      case KmCategory.personal:
        return Colors.blue;
      case KmCategory.work:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(KmCategory category) {
    switch (category) {
      case KmCategory.personal:
        return Icons.person;
      case KmCategory.work:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surface,
                          theme.colorScheme.surface.withAlpha(230),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme),
                        _buildContent(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: theme.colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(widget.selectedDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (_entries.isNotEmpty)
                  Text(
                    '${_entries.length} ${_entries.length == 1 ? 'entry' : 'entries'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            tooltip: 'Chiudi',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(maxHeight: 400), // Limita altezza
      child: _entries.isEmpty ? _buildEmptyState(theme) : _buildEntriesList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.route,
          size: 64,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'Nessun viaggio registrato',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aggiungi il tuo primo viaggio per questa data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildAddButton(theme),
      ],
    );
  }

  Widget _buildEntriesList(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...List.generate(_entries.length, (index) {
            final entry = _entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEntryCard(entry, index, theme),
            );
          }),
          const SizedBox(height: 16),
          _buildAddButton(theme),
        ],
      ),
    );
  }

  Widget _buildEntryCard(KmEntry entry, int index, ThemeData theme) {
    final categoryColor = _getCategoryColor(entry.category);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAddEditDialog(entry: entry, index: index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(entry.category),
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.category.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.kilometers} km',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddEditDialog(entry: entry, index: index);
                  } else if (value == 'delete') {
                    _deleteEntry(entry);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Modifica'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Elimina', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddEditDialog(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(_entries.isEmpty ? 'Aggiungi primo viaggio' : 'Aggiungi nuovo viaggio'),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Dialog per aggiungere/modificare entry
class _AddEditEntryDialog extends StatefulWidget {
  final KmEntry? entry;
  final DateTime selectedDate;
  final Function(KmEntry) onSave;

  const _AddEditEntryDialog({
    this.entry,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<_AddEditEntryDialog> createState() => _AddEditEntryDialogState();
}

class _AddEditEntryDialogState extends State<_AddEditEntryDialog> {
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