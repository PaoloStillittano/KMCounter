import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../models/km_entry.dart';
import 'dart:math' as math;

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

class _KmDetailCardState extends State<KmDetailCard> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  KmCategory _selectedCategory = KmCategory.personal;
  List<KmEntry> _existingEntries = [];
  int _currentEntryIndex = -1;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadExistingEntries();
  }

  void _loadExistingEntries() {
    _existingEntries = widget.controller.getEntriesForDate(widget.selectedDate);
    
    if (_existingEntries.isNotEmpty) {
      _setCurrentEntry(0);
    } else {
      _currentEntryIndex = -1;
      _kmController.text = '';
    }
  }

  void _setCurrentEntry(int index) {
    if (index >= 0 && index < _existingEntries.length) {
      setState(() {
        _currentEntryIndex = index;
        _kmController.text = _existingEntries[index].kilometers.toString();
        _selectedCategory = _existingEntries[index].category;
      });
    }
  }

  void _nextEntry() {
    if (_currentEntryIndex < _existingEntries.length - 1) {
      setState(() {
        _setCurrentEntry(_currentEntryIndex + 1);
      });
    }
  }

  void _previousEntry() {
    if (_currentEntryIndex > 0) {
      setState(() {
        _setCurrentEntry(_currentEntryIndex - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateHeader(widget.selectedDate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  
                  // Entry navigation indicator
                  if (_existingEntries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: _currentEntryIndex > 0 ? _previousEntry : null,
                            color: _currentEntryIndex > 0 ? theme.primaryColor : Colors.grey,
                          ),
                          Text(
                            '${_currentEntryIndex + 1}/${_existingEntries.length}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: _currentEntryIndex < _existingEntries.length - 1 ? _nextEntry : null,
                            color: _currentEntryIndex < _existingEntries.length - 1 ? theme.primaryColor : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),

                  /// Categoria
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Categoria:',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: KmCategory.values.map((category) {
                      return ChoiceChip(
                        label: Text(category.displayName),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  /// Input Km
                  TextFormField(
                    controller: _kmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Chilometri',
                      border: OutlineInputBorder(),
                      suffixText: 'km',
                    ),
                    validator: (value) {
                      final km = double.tryParse(value ?? '');
                      if (value == null || value.isEmpty) {
                        return 'Inserisci i chilometri';
                      } else if (km == null || km <= 0) {
                        return 'Valore non valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  /// Azioni
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_currentEntryIndex >= 0)
                        ElevatedButton.icon(
                          onPressed: _deleteEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text('Elimina'),
                        ),
                      ElevatedButton.icon(
                        onPressed: _saveEntry,
                        icon: const Icon(Icons.check),
                        label: Text(_currentEntryIndex >= 0 ? 'Modifica' : 'Salva'),
                      ),
                    ],
                  ),
                  
                  // Add new entry button
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextButton.icon(
                      onPressed: _prepareNewEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Aggiungi nuova entry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _prepareNewEntry() {
    setState(() {
      _currentEntryIndex = -1;
      _kmController.text = '';
      _selectedCategory = KmCategory.personal;
    });
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;

    final km = double.parse(_kmController.text);

    final entry = KmEntry(
      date: widget.selectedDate,
      kilometers: km,
      category: _selectedCategory,
    );

    if (_currentEntryIndex >= 0) {
      // Update existing entry
      final globalIndex = widget.controller.entries.indexOf(_existingEntries[_currentEntryIndex]);
      if (globalIndex >= 0) {
        widget.controller.updateEntry(globalIndex, entry);
        _showSnackbar('Entry aggiornata');
        _refreshEntries();
      }
    } else {
      // Add new entry
      widget.controller.addEntry(entry);
      _showSnackbar('Entry salvata');
      _refreshEntries();
    }
  }

  void _refreshEntries() {
    setState(() {
      _loadExistingEntries();
    });
  }

  void _deleteEntry() {
    if (_currentEntryIndex >= 0) {
      final globalIndex = widget.controller.entries.indexOf(_existingEntries[_currentEntryIndex]);
      if (globalIndex >= 0) {
        widget.controller.deleteEntry(globalIndex);
        _showSnackbar('Entry eliminata');
        
        // Refresh entries list and reset form if needed
        _existingEntries = widget.controller.getEntriesForDate(widget.selectedDate);
        if (_existingEntries.isEmpty) {
          _prepareNewEntry();
        } else {
          _setCurrentEntry(math.min(_currentEntryIndex, _existingEntries.length - 1));
        }
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDateHeader(DateTime date) {
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

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday ${date.day} $month';
  }

  @override
  void dispose() {
    _kmController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
