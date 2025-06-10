import 'package:excel/excel.dart' hide Border;
import '../models/km_entry.dart';
import './date_utils.dart';

Future<void> createDashboardSheet(
    Sheet sheet, List<KmEntry> entries, int year, int month) async {
  final monthName = DateUtils.getMonthName(month);

  final titleStyle = CellStyle(
    fontSize: 18,
    fontFamily: getFontFamily(FontFamily.Calibri),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    backgroundColorHex: ExcelColor.blue,
    fontColorHex: ExcelColor.white,
  );

  final headerStyle = CellStyle(
    fontSize: 12,
    bold: true,
    backgroundColorHex: ExcelColor.lightBlue,
    horizontalAlign: HorizontalAlign.Center,
    fontColorHex: ExcelColor.white,
  );

  final dataStyle = CellStyle(
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Center,
  );

  // Titolo principale
  var cell = sheet.cell(CellIndex.indexByString('A1'));
  cell.value = TextCellValue('REPORT CHILOMETRI - $monthName $year');
  cell.cellStyle = titleStyle;
  sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));

  // Data generazione
  cell = sheet.cell(CellIndex.indexByString('A2'));
  cell.value = TextCellValue(
      'Generato il: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} alle ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}');
  cell.cellStyle = dataStyle;
  sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('F2'));

  // Calcoli
  final totalKm = entries.fold(0.0, (sum, entry) => sum + entry.kilometers);
  final personalKm = entries
      .where((e) => e.category == KmCategory.personal)
      .fold(0.0, (sum, entry) => sum + entry.kilometers);
  final workKm = entries
      .where((e) => e.category == KmCategory.work)
      .fold(0.0, (sum, entry) => sum + entry.kilometers);

  final daysInMonth = DateTime(year, month + 1, 0).day;
  final avgDaily = totalKm / daysInMonth;
  final daysWithTrips = entries.map((e) => e.date.day).toSet().length;

  // Sezione riassunto
  int row = 4;
  cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
  cell.value = TextCellValue('RIASSUNTO MENSILE');
  cell.cellStyle = headerStyle;
  sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

  row++;
  _addKeyValueRow(
      sheet, row++, 'Totale Chilometri:', '${totalKm.toStringAsFixed(1)} km');
  _addKeyValueRow(sheet, row++, 'Numero Viaggi:', '${entries.length}');
  _addKeyValueRow(
      sheet, row++, 'Giorni con Viaggi:', '$daysWithTrips di $daysInMonth');
  _addKeyValueRow(sheet, row++, 'Media per Viaggio:',
      '${entries.isNotEmpty ? (totalKm / entries.length).toStringAsFixed(1) : "0.0"} km');
  _addKeyValueRow(
      sheet, row++, 'Media Giornaliera:', '${avgDaily.toStringAsFixed(1)} km');

  // Sezione categorie
  row += 2;
  cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
  cell.value = TextCellValue('SUDDIVISIONE PER CATEGORIA');
  cell.cellStyle = headerStyle;
  sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

  row++;
  if (totalKm > 0) {
    final personalTrips =
        entries.where((e) => e.category == KmCategory.personal).length;
    final workTrips =
        entries.where((e) => e.category == KmCategory.work).length;
    final personalPerc = (personalKm / totalKm * 100);
    final workPerc = (workKm / totalKm * 100);

    _addKeyValueRow(sheet, row++, 'Personale:',
        '${personalKm.toStringAsFixed(1)} km (${personalPerc.toStringAsFixed(1)}%) - $personalTrips viaggi');
    _addKeyValueRow(sheet, row++, 'Lavoro:',
        '${workKm.toStringAsFixed(1)} km (${workPerc.toStringAsFixed(1)}%) - $workTrips viaggi');
  }

  // Record del mese
  if (entries.isNotEmpty) {
    row += 2;
    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('RECORD DEL MESE');
    cell.cellStyle = headerStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

    row++;
    final maxKmEntry =
        entries.reduce((a, b) => a.kilometers > b.kilometers ? a : b);
    final minKmEntry =
        entries.reduce((a, b) => a.kilometers < b.kilometers ? a : b);

    _addKeyValueRow(sheet, row++, 'Viaggio più lungo:',
        '${maxKmEntry.kilometers.toStringAsFixed(1)} km (${maxKmEntry.date.day}/${maxKmEntry.date.month})');
    _addKeyValueRow(sheet, row++, 'Viaggio più corto:',
        '${minKmEntry.kilometers.toStringAsFixed(1)} km (${minKmEntry.date.day}/${minKmEntry.date.month})');

    // Trova il giorno con più km
    final dailyTotals = <String, double>{};
    for (final entry in entries) {
      final dateKey = '${entry.date.day}/${entry.date.month}';
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + entry.kilometers;
    }

    if (dailyTotals.isNotEmpty) {
      final maxDayEntry =
          dailyTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      _addKeyValueRow(sheet, row++, 'Giorno con più km:',
          '${maxDayEntry.value.toStringAsFixed(1)} km (${maxDayEntry.key})');
    }
  }

  // Imposta larghezza colonne
  sheet.setColumnWidth(0, 25);
  sheet.setColumnWidth(1, 30);
  sheet.setColumnWidth(2, 15);
  sheet.setColumnWidth(3, 15);
}

Future<void> createDataSheet(
    Sheet sheet, List<KmEntry> entries, int year, int month) async {
  final headerStyle = CellStyle(
    fontSize: 12,
    bold: true,
    backgroundColorHex: ExcelColor.lightGreen,
    horizontalAlign: HorizontalAlign.Center,
  );

  final dataStyle = CellStyle(
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Center,
  );

  // Headers
  final headers = ['Data', 'Chilometri', 'Categoria', 'Giorno della Settimana'];
  for (int i = 0; i < headers.length; i++) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.value = TextCellValue(headers[i]);
    cell.cellStyle = headerStyle;
  }

  // Dati
  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final row = i + 1;

    // Data
    var cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue(
        '${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}');
    cell.cellStyle = dataStyle;

    // Chilometri
    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    cell.value = DoubleCellValue(entry.kilometers);
    cell.cellStyle = dataStyle;

    // Categoria
    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
    cell.value = TextCellValue(entry.category.displayName);
    cell.cellStyle = dataStyle;

    // Giorno
    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    cell.value = TextCellValue(_getDayOfWeekName(entry.date.weekday));
    cell.cellStyle = dataStyle;
  }

  // Imposta larghezza colonne
  sheet.setColumnWidth(0, 15);
  sheet.setColumnWidth(1, 12);
  sheet.setColumnWidth(2, 15);
  sheet.setColumnWidth(3, 20);
}

Future<void> createStatsSheet(
    Sheet sheet, List<KmEntry> entries, int year, int month) async {
  final headerStyle = CellStyle(
    fontSize: 12,
    bold: true,
    backgroundColorHex: ExcelColor.yellow,
    horizontalAlign: HorizontalAlign.Center,
  );

  final dataStyle = CellStyle(
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Center,
  );

  int row = 0;

  // Analisi per giorno della settimana
  var cell =
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
  cell.value = TextCellValue('ANALISI PER GIORNO DELLA SETTIMANA');
  cell.cellStyle = headerStyle;
  sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

  row++;
  final weekHeaders = ['Giorno', 'Viaggi', 'Chilometri', 'Media'];
  for (int i = 0; i < weekHeaders.length; i++) {
    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
    cell.value = TextCellValue(weekHeaders[i]);
    cell.cellStyle = headerStyle;
  }
  row++;

  final weekdayData = <int, List<KmEntry>>{};
  for (final entry in entries) {
    weekdayData.putIfAbsent(entry.date.weekday, () => []).add(entry);
  }

  for (int i = 1; i <= 7; i++) {
    final dayEntries = weekdayData[i] ?? [];
    final dayName = _getDayOfWeekName(i);
    final dayKm = dayEntries.fold(0.0, (sum, entry) => sum + entry.kilometers);
    final avgKm = dayEntries.isNotEmpty ? (dayKm / dayEntries.length) : 0.0;

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue(dayName);
    cell.cellStyle = dataStyle;

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    cell.value = IntCellValue(dayEntries.length);
    cell.cellStyle = dataStyle;

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
    cell.value = DoubleCellValue(dayKm);
    cell.cellStyle = dataStyle;

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    cell.value = DoubleCellValue(avgKm);
    cell.cellStyle = dataStyle;

    row++;
  }

  // Analisi settimanale
  row += 2;
  cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
  cell.value = TextCellValue('ANALISI PER SETTIMANE DEL MESE');
  cell.cellStyle = headerStyle;
  sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

  row++;
  final weeklyHeaders = ['Settimana', 'Periodo', 'Viaggi', 'Chilometri'];
  for (int i = 0; i < weeklyHeaders.length; i++) {
    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
    cell.value = TextCellValue(weeklyHeaders[i]);
    cell.cellStyle = headerStyle;
  }
  row++;

  final weeklyData = <int, List<KmEntry>>{};
  for (final entry in entries) {
    final weekOfMonth = ((entry.date.day - 1) ~/ 7) + 1;
    weeklyData.putIfAbsent(weekOfMonth, () => []).add(entry);
  }

  weeklyData.forEach((week, weekEntries) {
    weekEntries.sort((a, b) => a.date.compareTo(b.date));
    final startDay = weekEntries.first.date.day;
    final endDay = weekEntries.last.date.day;
    final weekKm =
        weekEntries.fold(0.0, (sum, entry) => sum + entry.kilometers);
    final monthName = DateUtils.getMonthName(month);

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('Settimana $week');
    cell.cellStyle = dataStyle;

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    cell.value = TextCellValue('$startDay-$endDay $monthName');
    cell.cellStyle = dataStyle;

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
    cell.value = IntCellValue(weekEntries.length);
    cell.cellStyle = dataStyle;

    cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    cell.value = DoubleCellValue(weekKm);
    cell.cellStyle = dataStyle;

    row++;
  });

  // Imposta larghezza colonne
  sheet.setColumnWidth(0, 20);
  sheet.setColumnWidth(1, 20);
  sheet.setColumnWidth(2, 12);
  sheet.setColumnWidth(3, 15);
}

void _addKeyValueRow(Sheet sheet, int row, String key, String value) {
  final keyStyle = CellStyle(
    fontSize: 11,
    bold: true,
    horizontalAlign: HorizontalAlign.Left,
  );

  final valueStyle = CellStyle(
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Left,
  );

  var cell =
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
  cell.value = TextCellValue(key);
  cell.cellStyle = keyStyle;

  cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
  cell.value = TextCellValue(value);
  cell.cellStyle = valueStyle;
}

String _getDayOfWeekName(int weekday) {
  const dayNames = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica'
  ];
  return dayNames[weekday - 1];
}

// String getMonthName(int month) {
//   const monthNames = [
//     'Gennaio',
//     'Febbraio',
//     'Marzo',
//     'Aprile',
//     'Maggio',
//     'Giugno',
//     'Luglio',
//     'Agosto',
//     'Settembre',
//     'Ottobre',
//     'Novembre',
//     'Dicembre'
//   ];
//   return monthNames[month - 1];
// }
