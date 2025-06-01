import 'package:flutter/foundation.dart';
import '../models/km_entry.dart';
import '../services/database_service.dart';

class KmController extends ChangeNotifier {
  List<KmEntry> _entries = [];
  
  KmController() {
    _loadEntries();
  }
  
  List<KmEntry> get entries => _entries;

  get todayKm => null;
  
  Future<void> _loadEntries() async {
    _entries = DatabaseService.getAllKmEntries();
    notifyListeners();
  }
  
  Future<void> addEntry(KmEntry entry) async {
    await DatabaseService.addKmEntry(entry);
    _entries = DatabaseService.getAllKmEntries();
    notifyListeners();
  }
  
  Future<void> updateEntry(int index, KmEntry entry) async {
    await DatabaseService.updateKmEntry(index, entry);
    _entries = DatabaseService.getAllKmEntries();
    notifyListeners();
  }
  
  Future<void> deleteEntry(int index) async {
    await DatabaseService.deleteKmEntry(index);
    _entries = DatabaseService.getAllKmEntries();
    notifyListeners();
  }
  
  List<KmEntry> getEntriesForDate(DateTime date) {
    return _entries.where((entry) => 
      entry.date.year == date.year && 
      entry.date.month == date.month && 
      entry.date.day == date.day
    ).toList();
  }
  
  double getTotalKilometers() {
    return _entries.fold(0, (sum, entry) => sum + entry.kilometers);
  }
  
  double getTotalKilometersForCategory(KmCategory category) {
    return _entries
        .where((entry) => entry.category == category)
        .fold(0, (sum, entry) => sum + entry.kilometers);
  }
  
  double getTotalKilometersForMonth(int year, int month) {
    return _entries
        .where((entry) => entry.date.year == year && entry.date.month == month)
        .fold(0, (sum, entry) => sum + entry.kilometers);
  }
  
  double getTotalKilometersForMonthAndCategory(int year, int month, KmCategory category) {
    return _entries
        .where((entry) => 
            entry.date.year == year && 
            entry.date.month == month && 
            entry.category == category)
        .fold(0, (sum, entry) => sum + entry.kilometers);
  }
}