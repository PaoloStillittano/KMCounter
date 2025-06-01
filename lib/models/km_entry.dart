import 'package:hive/hive.dart';

part 'km_entry.g.dart';

@HiveType(typeId: 0)
enum KmCategory {
  @HiveField(0)
  personal,
  @HiveField(1)
  work,
}

extension KmCategoryExtension on KmCategory {
  String get displayName {
    switch (this) {
      case KmCategory.personal:
        return 'Personale';
      case KmCategory.work:
        return 'Lavoro';
    }
  }
}

@HiveType(typeId: 1)
class KmEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final double kilometers;
  
  @HiveField(2)
  final KmCategory category;

  KmEntry({
    required this.date,
    required this.kilometers,
    required this.category,
  });
}