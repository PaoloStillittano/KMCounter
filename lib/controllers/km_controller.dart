// controllers/km_controller.dart
import 'package:flutter/foundation.dart';
import '../models/km_entry.dart';

class KmController extends ChangeNotifier {
  final List<KmEntry> _entries = [];
  DateTime _selectedDate = DateTime.now();

  List<KmEntry> get entries => List.unmodifiable(_entries);
  DateTime get selectedDate => _selectedDate;

  // Ottieni entries per una data specifica
  List<KmEntry> getEntriesForDate(DateTime date) {
    return _entries.where((entry) => 
        entry.date.year == date.year &&
        entry.date.month == date.month &&
        entry.date.day == date.day
    ).toList();
  }

  // Ottieni totale km per il mese corrente
  double getTotalKmForCurrentMonth({KmCategory? category}) {
    final now = DateTime.now();
    return _entries
        .where((entry) => 
            entry.date.year == now.year &&
            entry.date.month == now.month &&
            (category == null || entry.category == category))
        .fold(0.0, (sum, entry) => sum + entry.kilometers);
  }

  // Aggiungi una nuova entry
  void addEntry(KmEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  // Modifica un'entry esistente
  void updateEntry(int index, KmEntry updatedEntry) {
    if (index >= 0 && index < _entries.length) {
      _entries[index] = updatedEntry;
      notifyListeners();
    }
  }

  // Elimina un'entry
  void deleteEntry(int index) {
    if (index >= 0 && index < _entries.length) {
      _entries.removeAt(index);
      notifyListeners();
    }
  }

  // Cambia data selezionata
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}