// services/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart' hide Border;
import '../models/km_entry.dart';

class ExportService {
  static Future<void> exportMonthlyDataToExcel({
    required BuildContext context,
    required List<KmEntry> entries,
    required int year,
    required int month,
  }) async {
    try {
      // Mostra dialog di loading migliorato
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generazione file Excel...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

      // Filtra le entries per il mese specificato
      final monthlyEntries = entries.where((entry) =>
        entry.date.year == year && entry.date.month == month
      ).toList();

      if (monthlyEntries.isEmpty) {
        Navigator.pop(context); // Chiudi loading
        _showMessage(context, 'Nessun dato trovato per questo mese', isError: true);
        return;
      }

      // Ordina per data
      monthlyEntries.sort((a, b) => a.date.compareTo(b.date));

      // Genera il file Excel
      final excel = await _generateExcelFile(monthlyEntries, year, month);
      
      // Crea il file
      final fileName = 'Kilometri_${_getMonthName(month)}_$year.xlsx';
      final file = await _createExcelFile(excel, fileName);

      Navigator.pop(context); // Chiudi loading

      // Mostra dialog per scegliere l'azione
      await _showExportSuccessDialog(context, file, monthlyEntries.length);

    } catch (e) {
      Navigator.pop(context); // Chiudi loading in caso di errore
      _showMessage(context, 'Errore durante l\'esportazione: $e', isError: true);
    }
  }

  static Future<Excel> _generateExcelFile(List<KmEntry> entries, int year, int month) async {
    final excel = Excel.createExcel();
    
    // Rimuovi il foglio di default
    excel.delete('Sheet1');
    
    // Crea i fogli di lavoro
    final dashboardSheet = excel['Dashboard'];
    final dataSheet = excel['Dati Viaggi'];
    final statsSheet = excel['Statistiche'];
    
    await _createDashboardSheet(dashboardSheet, entries, year, month);
    await _createDataSheet(dataSheet, entries, year, month);
    await _createStatsSheet(statsSheet, entries, year, month);
    
    return excel;
  }

  static Future<void> _createDashboardSheet(Sheet sheet, List<KmEntry> entries, int year, int month) async {
    final monthName = _getMonthName(month);
    
    // Stili
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
    cell.value = TextCellValue('Generato il: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} alle ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}');
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
    _addKeyValueRow(sheet, row++, 'Totale Chilometri:', '${totalKm.toStringAsFixed(1)} km');
    _addKeyValueRow(sheet, row++, 'Numero Viaggi:', '${entries.length}');
    _addKeyValueRow(sheet, row++, 'Giorni con Viaggi:', '$daysWithTrips di $daysInMonth');
    _addKeyValueRow(sheet, row++, 'Media per Viaggio:', '${entries.isNotEmpty ? (totalKm / entries.length).toStringAsFixed(1) : "0.0"} km');
    _addKeyValueRow(sheet, row++, 'Media Giornaliera:', '${avgDaily.toStringAsFixed(1)} km');

    // Sezione categorie
    row += 2;
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('SUDDIVISIONE PER CATEGORIA');
    cell.cellStyle = headerStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), 
               CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

    row++;
    if (totalKm > 0) {
      final personalTrips = entries.where((e) => e.category == KmCategory.personal).length;
      final workTrips = entries.where((e) => e.category == KmCategory.work).length;
      final personalPerc = (personalKm / totalKm * 100);
      final workPerc = (workKm / totalKm * 100);
      
      _addKeyValueRow(sheet, row++, 'Personale:', '${personalKm.toStringAsFixed(1)} km (${personalPerc.toStringAsFixed(1)}%) - $personalTrips viaggi');
      _addKeyValueRow(sheet, row++, 'Lavoro:', '${workKm.toStringAsFixed(1)} km (${workPerc.toStringAsFixed(1)}%) - $workTrips viaggi');
    }

    // Record del mese
    if (entries.isNotEmpty) {
      row += 2;
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      cell.value = TextCellValue('RECORD DEL MESE');
      cell.cellStyle = headerStyle;
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), 
                 CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

      row++;
      final maxKmEntry = entries.reduce((a, b) => a.kilometers > b.kilometers ? a : b);
      final minKmEntry = entries.reduce((a, b) => a.kilometers < b.kilometers ? a : b);
      
      _addKeyValueRow(sheet, row++, 'Viaggio più lungo:', '${maxKmEntry.kilometers.toStringAsFixed(1)} km (${maxKmEntry.date.day}/${maxKmEntry.date.month})');
      _addKeyValueRow(sheet, row++, 'Viaggio più corto:', '${minKmEntry.kilometers.toStringAsFixed(1)} km (${minKmEntry.date.day}/${minKmEntry.date.month})');
      
      // Trova il giorno con più km
      final dailyTotals = <String, double>{};
      for (final entry in entries) {
        final dateKey = '${entry.date.day}/${entry.date.month}';
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + entry.kilometers;
      }
      
      if (dailyTotals.isNotEmpty) {
        final maxDayEntry = dailyTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
        _addKeyValueRow(sheet, row++, 'Giorno con più km:', '${maxDayEntry.value.toStringAsFixed(1)} km (${maxDayEntry.key})');
      }
    }

    // Imposta larghezza colonne
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
  }

  static Future<void> _createDataSheet(Sheet sheet, List<KmEntry> entries, int year, int month) async {
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
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Dati
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final row = i + 1;
      
      // Data
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      cell.value = TextCellValue('${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}');
      cell.cellStyle = dataStyle;
      
      // Chilometri
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      cell.value = DoubleCellValue(entry.kilometers);
      cell.cellStyle = dataStyle;
      
      // Categoria
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      cell.value = TextCellValue(entry.category.displayName);
      cell.cellStyle = dataStyle;
      
      // Giorno
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      cell.value = TextCellValue(_getDayOfWeekName(entry.date.weekday));
      cell.cellStyle = dataStyle;
    }

    // Imposta larghezza colonne
    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 20);
  }

  static Future<void> _createStatsSheet(Sheet sheet, List<KmEntry> entries, int year, int month) async {
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
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('ANALISI PER GIORNO DELLA SETTIMANA');
    cell.cellStyle = headerStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), 
               CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    
    row++;
    final weekHeaders = ['Giorno', 'Viaggi', 'Chilometri', 'Media'];
    for (int i = 0; i < weekHeaders.length; i++) {
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
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
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      cell.value = TextCellValue(dayName);
      cell.cellStyle = dataStyle;
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      cell.value = IntCellValue(dayEntries.length);
      cell.cellStyle = dataStyle;
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      cell.value = DoubleCellValue(dayKm);
      cell.cellStyle = dataStyle;
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
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
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
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
      final weekKm = weekEntries.fold(0.0, (sum, entry) => sum + entry.kilometers);
      final monthName = _getMonthName(month);
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      cell.value = TextCellValue('Settimana $week');
      cell.cellStyle = dataStyle;
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      cell.value = TextCellValue('$startDay-$endDay $monthName');
      cell.cellStyle = dataStyle;
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      cell.value = IntCellValue(weekEntries.length);
      cell.cellStyle = dataStyle;
      
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
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

  static void _addKeyValueRow(Sheet sheet, int row, String key, String value) {
    final keyStyle = CellStyle(
      fontSize: 11,
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
    );
    
    final valueStyle = CellStyle(
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
    );

    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue(key);
    cell.cellStyle = keyStyle;
    
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = valueStyle;
  }

  static Future<File> _createExcelFile(Excel excel, String fileName) async {
    // Ottieni la directory di download
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Richiedi permessi se necessario
      await _requestStoragePermission();
      
      // Per Android, prova prima la directory di download
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      // Per iOS e altri sistemi
      directory = await getApplicationDocumentsDirectory();
    }
    
    final file = File('${directory!.path}/$fileName');
    
    // Salva il file Excel
    final List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }
    
    return file;
  }

  static Future<void> _showExportSuccessDialog(
    BuildContext context, 
    File file, 
    int entriesCount,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Esportazione Completata',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'File Excel creato con successo!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.path.split('/').last,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.analytics, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text('$entriesCount viaggi esportati'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<int>(
                      future: file.length(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Row(
                            children: [
                              Icon(Icons.hourglass_empty, color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text('Calcolando dimensioni...'),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Errore nel calcolo dimensione'),
                            ],
                          );
                        } else {
                          final sizeKB = (snapshot.data! / 1024).toStringAsFixed(1);
                          return Row(
                            children: [
                              const Icon(Icons.storage, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text('$sizeKB KB'),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text('File Excel nativo'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Il file include 3 fogli: Dashboard, Dati Viaggi e Statistiche dettagliate',
                        style: TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Chiudi'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _shareFile(file, context);
            },
            icon: const Icon(Icons.share),
            label: const Text('Condividi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _shareFile(File file, BuildContext context) async {
    try {
      if (!await file.exists()) {
        _showMessage(context, 'File non trovato', isError: true);
        return;
      }

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dati chilometrici esportati da Daily Counter\n\n📊 File Excel con 3 fogli di lavoro\n📅 ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
        subject: 'Export Chilometri - ${file.path.split('/').last}',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
      
      debugPrint('Condivisione completata: ${result.status}');
      
      if (result.status == ShareResultStatus.success) {
        _showMessage(context, 'File condiviso con successo! 📤');
      }
    } catch (e) {
      debugPrint('Errore nella condivisione: $e');
      _showMessage(context, 'Errore nella condivisione. Percorso copiato negli appunti.', isError: true);
      await _copyPathToClipboard(file);
    }
  }

  static Future<void> _copyPathToClipboard(File file) async {
    try {
      await Clipboard.setData(ClipboardData(text: file.path));
      debugPrint('Percorso file copiato negli appunti: ${file.path}');
    } catch (e) {
      debugPrint('Errore nella copia: $e');
    }
  }

  static void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: isError 
            ? Colors.red[600] 
            : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  static String _getMonthName(int month) {
    const monthNames = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return monthNames[month - 1];
  }

  static String _getDayOfWeekName(int weekday) {
    const dayNames = [
      'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'
    ];
    return dayNames[weekday - 1];
  }

  // Metodo per richiedere permessi su Android
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }
}