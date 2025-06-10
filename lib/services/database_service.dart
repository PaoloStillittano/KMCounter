import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/km_entry.dart';

class DatabaseService {
  static const String kmEntriesBoxName = 'km_entries';
  
  static Future<void> initialize() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    Hive.registerAdapter(KmCategoryAdapter());
    Hive.registerAdapter(KmEntryAdapter());
    
    await Hive.openBox<KmEntry>(kmEntriesBoxName);
  }
  
  static Box<KmEntry> getKmEntriesBox() {
    return Hive.box<KmEntry>(kmEntriesBoxName);
  }
  
  static Future<void> addKmEntry(KmEntry entry) async {
    final box = getKmEntriesBox();
    await box.add(entry);
  }
  
  static Future<void> updateKmEntry(int index, KmEntry entry) async {
    final box = getKmEntriesBox();
    await box.putAt(index, entry);
  }
  
  static Future<void> deleteKmEntry(int index) async {
    final box = getKmEntriesBox();
    await box.deleteAt(index);
  }
  
  static List<KmEntry> getAllKmEntries() {
    final box = getKmEntriesBox();
    return box.values.toList();
  }
  
  static List<KmEntry> getEntriesForDate(DateTime date) {
    final box = getKmEntriesBox();
    return box.values.where((entry) => 
      entry.date.year == date.year && 
      entry.date.month == date.month && 
      entry.date.day == date.day
    ).toList();
  }
}