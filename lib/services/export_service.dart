// services/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/km_entry.dart';

class ExportService {
  static Future<void> exportMonthlyDataToCsv({
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
              Text('Generazione file CSV...', style: TextStyle(fontSize: 16)),
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

      // Genera il contenuto CSV
      final csvContent = _generateCsvContent(monthlyEntries, year, month);
      
      // Crea il file
      final fileName = 'Kilometri_${_getMonthName(month)}_$year.csv';
      final file = await _createCsvFile(csvContent, fileName);

      Navigator.pop(context); // Chiudi loading

      // Mostra dialog per scegliere l'azione
      await _showExportSuccessDialog(context, file, monthlyEntries.length);

    } catch (e) {
      Navigator.pop(context); // Chiudi loading in caso di errore
      _showMessage(context, 'Errore durante l\'esportazione: $e', isError: true);
    }
  }

  static String _generateCsvContent(List<KmEntry> entries, int year, int month) {
    final buffer = StringBuffer();
    
    // BOM per UTF-8 (migliora compatibilità Excel)
    buffer.write('\uFEFF');
    
    // TITOLO DEL REPORT
    final monthName = _getMonthName(month);
    buffer.writeln('REPORT CHILOMETRI - $monthName $year');
    buffer.writeln('Generato il: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} alle ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}');
    buffer.writeln('');
    
    // SEZIONE DATI PRINCIPALI
    buffer.writeln('DATI VIAGGI');
    buffer.writeln('Data,Chilometri,Categoria,Giorno');
    
    // Dati dei viaggi
    for (final entry in entries) {
      final dateStr = '${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}';
      final kmStr = entry.kilometers.toStringAsFixed(1);
      final categoryStr = entry.category.displayName;
      final dayOfWeek = _getDayOfWeekName(entry.date.weekday);
      
      buffer.writeln('$dateStr,$kmStr,$categoryStr,$dayOfWeek');
    }
    
    // Separatore visivo
    buffer.writeln('');
    buffer.writeln('');
    
    // SEZIONE STATISTICHE GENERALI
    buffer.writeln('STATISTICHE GENERALI');
    buffer.writeln('Descrizione,Valore,Unità');
    
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
    
    buffer.writeln('Totale Chilometri,${totalKm.toStringAsFixed(1)},km');
    buffer.writeln('Numero Viaggi,${entries.length},viaggi');
    buffer.writeln('Giorni con Viaggi,$daysWithTrips,giorni');
    buffer.writeln('Media per Viaggio,${entries.isNotEmpty ? (totalKm / entries.length).toStringAsFixed(1) : "0.0"},km');
    buffer.writeln('Media Giornaliera,${avgDaily.toStringAsFixed(1)},km');
    buffer.writeln('');
    
    // SEZIONE SUDDIVISIONE PER CATEGORIA
    buffer.writeln('SUDDIVISIONE PER CATEGORIA');
    buffer.writeln('Categoria,Chilometri,Viaggi,Percentuale');
    
    if (totalKm > 0) {
      final personalTrips = entries.where((e) => e.category == KmCategory.personal).length;
      final workTrips = entries.where((e) => e.category == KmCategory.work).length;
      final personalPerc = (personalKm / totalKm * 100);
      final workPerc = (workKm / totalKm * 100);
      
      buffer.writeln('Personale,${personalKm.toStringAsFixed(1)},$personalTrips,${personalPerc.toStringAsFixed(1)}%');
      buffer.writeln('Lavoro,${workKm.toStringAsFixed(1)},$workTrips,${workPerc.toStringAsFixed(1)}%');
    }
    buffer.writeln('');
    
    // SEZIONE ANALISI SETTIMANALE
    buffer.writeln('ANALISI PER GIORNO DELLA SETTIMANA');
    buffer.writeln('Giorno,Viaggi,Chilometri,Media');
    
    final weekdayData = <int, List<KmEntry>>{};
    for (final entry in entries) {
      weekdayData.putIfAbsent(entry.date.weekday, () => []).add(entry);
    }
    
    for (int i = 1; i <= 7; i++) {
      final dayEntries = weekdayData[i] ?? [];
      final dayName = _getDayOfWeekName(i);
      final dayKm = dayEntries.fold(0.0, (sum, entry) => sum + entry.kilometers);
      final avgKm = dayEntries.isNotEmpty ? (dayKm / dayEntries.length).toStringAsFixed(1) : '0.0';
      
      buffer.writeln('$dayName,${dayEntries.length},${dayKm.toStringAsFixed(1)},$avgKm');
    }
    buffer.writeln('');
    
    // SEZIONE ANALISI SETTIMANALE (per settimane del mese)
    buffer.writeln('ANALISI PER SETTIMANE DEL MESE');
    buffer.writeln('Settimana,Periodo,Viaggi,Chilometri');
    
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
      
      buffer.writeln('Settimana $week,$startDay-$endDay $monthName,${weekEntries.length},${weekKm.toStringAsFixed(1)}');
    });
    buffer.writeln('');
    
    // SEZIONE RECORD
    if (entries.isNotEmpty) {
      buffer.writeln('RECORD DEL MESE');
      buffer.writeln('Descrizione,Valore,Data');
      
      final maxKmEntry = entries.reduce((a, b) => a.kilometers > b.kilometers ? a : b);
      final minKmEntry = entries.reduce((a, b) => a.kilometers < b.kilometers ? a : b);
      
      buffer.writeln('Viaggio più lungo,${maxKmEntry.kilometers.toStringAsFixed(1)} km,${maxKmEntry.date.day}/${maxKmEntry.date.month}/${maxKmEntry.date.year}');
      buffer.writeln('Viaggio più corto,${minKmEntry.kilometers.toStringAsFixed(1)} km,${minKmEntry.date.day}/${minKmEntry.date.month}/${minKmEntry.date.year}');
      
      // Trova il giorno con più km
      final dailyTotals = <String, double>{};
      for (final entry in entries) {
        final dateKey = '${entry.date.day}/${entry.date.month}/${entry.date.year}';
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + entry.kilometers;
      }
      
      if (dailyTotals.isNotEmpty) {
        final maxDayEntry = dailyTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
        buffer.writeln('Giorno con più km,${maxDayEntry.value.toStringAsFixed(1)} km,${maxDayEntry.key}');
      }
      
      buffer.writeln('');
    }
    
    // INFORMAZIONI TECNICHE
    buffer.writeln('INFORMAZIONI FILE');
    buffer.writeln('Campo,Valore');
    buffer.writeln('Applicazione,Daily Counter');
    buffer.writeln('Versione formato,CSV 1.0');
    buffer.writeln('Encoding,UTF-8');
    buffer.writeln('Separatore,Virgola');
    
    return buffer.toString();
  }

  // Funzione per escape dei campi CSV
  static String _escapeCSVField(String field) {
    // Se il campo contiene virgole, virgolette o newline, deve essere racchiuso tra virgolette
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      // Doppia le virgolette interne
      return field.replaceAll('"', '""');
    }
    return field;
  }

  static Future<File> _createCsvFile(String content, String fileName) async {
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
    
    // Scrivi con encoding UTF-8 e BOM per Excel
    await file.writeAsString(content, encoding: const Utf8Codec());
    
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
                'File CSV creato con successo e ottimizzato per Excel!',
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
                        const Icon(Icons.description, color: Colors.blue, size: 20),
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
                        Text('Compatibile con Excel'),
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
                        'Il file include statistiche dettagliate e formattazione ottimizzata per Excel',
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
      // Verifica che il file esista
      if (!await file.exists()) {
        _showMessage(context, 'File non trovato', isError: true);
        return;
      }

      // Usa shareXFiles per condividere il file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dati chilometrici esportati da Daily Counter\n\n📊 File ottimizzato per Excel\n📅 ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
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
      // Fallback: copia il percorso negli appunti
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
        // Prova con i permessi più specifici per Android 11+
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
      return status.isGranted;
    }
    return true; // iOS non ha bisogno di permessi per l'app directory
  }
}