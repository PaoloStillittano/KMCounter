// services/export_service.dart
import 'dart:io';
import 'package:counter/utils/excel_sheet.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart' hide Border;
import '../models/km_entry.dart';
import 'package:counter/utils/date_utils.dart';

class ExportService {
  static Future<void> exportMonthlyDataToExcel({
    required BuildContext context,
    required List<KmEntry> entries,
    required int year,
    required int month,
  }) async {
    try {
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

      final monthlyEntries = entries.where((entry) =>
        entry.date.year == year && entry.date.month == month
      ).toList();

      if (monthlyEntries.isEmpty) {
        Navigator.pop(context); 
        _showMessage(context, 'Nessun dato trovato per questo mese', isError: true);
        return;
      }

      monthlyEntries.sort((a, b) => a.date.compareTo(b.date));

      final excel = await _generateExcelFile(monthlyEntries, year, month);
      
      final fileName = 'Kilometri_${DateUtils.getMonthName(month)}_$year.xlsx';
      final file = await _createExcelFile(excel, fileName);

      Navigator.pop(context); 

      await _showExportSuccessDialog(context, file, monthlyEntries.length);

    } catch (e) {
      Navigator.pop(context);
      _showMessage(context, 'Errore durante l\'esportazione: $e', isError: true);
    }
  }

  static Future<Excel> _generateExcelFile(List<KmEntry> entries, int year, int month) async {
    final excel = Excel.createExcel();
    
    excel.delete('Sheet1');
    
    final dashboardSheet = excel['Dashboard'];
    final dataSheet = excel['Dati Viaggi'];
    final statsSheet = excel['Statistiche'];
    
    await createDashboardSheet(dashboardSheet, entries, year, month);
    await createDataSheet(dataSheet, entries, year, month);
    await createStatsSheet(statsSheet, entries, year, month);
    
    return excel;
  }

  static Future<File> _createExcelFile(Excel excel, String fileName) async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      await _requestStoragePermission();
      
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    final file = File('${directory!.path}/$fileName');
    
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
        text: 'Dati chilometrici esportati da Daily Counter\n\n📊 File Excel con 3 fogli di lavoro\n📅 ${DateUtils.getMonthName(DateTime.now().month)} ${DateTime.now().year}',
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