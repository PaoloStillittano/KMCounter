class KmEntry {
  final DateTime date;
  final double kilometers;
  final KmCategory category;
  final String? notes;

  KmEntry({
    required this.date,
    required this.kilometers,
    required this.category,
    this.notes,
  });

  KmEntry copyWith({
    DateTime? date,
    double? kilometers,
    KmCategory? category,
    String? notes,
  }) {
    return KmEntry(
      date: date ?? this.date,
      kilometers: kilometers ?? this.kilometers,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}

enum KmCategory {
  personal('Personale'),
  work('Lavoro');

  const KmCategory(this.displayName);
  final String displayName;
}