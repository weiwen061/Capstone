import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show File;
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart'; // REQUIRED hardware component

// Conditional import for cross-platform support
import 'mobile_save_helper.dart' if (dart.library.html) 'web_save_helper.dart';

class ExcelExportHelper {
  static Future<void> exportJsonToFile(
      List<Map<String, dynamic>> jsonData, String fileName,
      {String format = 'xlsx', BuildContext? context}) async {
    try {
      if (jsonData.isEmpty) throw 'No data to export';

      if (format == 'xlsx') {
        final excel = Excel.createExcel();
        final sheet = excel['Sheet1'];

        final headers = jsonData.first.keys.toList();
        sheet.appendRow(headers.map((h) => TextCellValue(h.toString())).toList());

        for (var row in jsonData) {
          sheet.appendRow(headers.map((key) => TextCellValue(row[key]?.toString() ?? '')).toList());
        }

        final excelBytes = excel.encode();
        if (excelBytes == null) throw 'Failed to encode Excel';

        if (kIsWeb) {
          saveFile(excelBytes, fileName, 'xlsx');
        } else {
          // Fixed pathing for your Samsung device
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName.xlsx';
          final file = File(filePath);
          await file.create(recursive: true);
          await file.writeAsBytes(excelBytes);
        }
      } else if (format == 'csv') {
        final headers = jsonData.first.keys.toList();
        final rows = [
          headers,
          ...jsonData.map((row) => headers.map((h) => row[h] ?? '').toList())
        ];
        final csvString = rows.map((r) => r.join(',')).join('\n');

        if (kIsWeb) {
          final bytes = utf8.encode(csvString);
          saveFile(bytes, fileName, 'csv');
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName.csv';
          await File(filePath).writeAsString(csvString);
        }
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported $fileName.$format successfully')),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }

  static Future<void> exportPerformanceFromFirestore(
      String classId, String className, String subjectName,
      {BuildContext? context}) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      final performanceSnapshot = await FirebaseFirestore.instance
          .collection('performance')
          .where('classId', isEqualTo: classId)
          .get();

      List<Map<String, dynamic>> exportData = [];

      for (var student in studentsSnapshot.docs) {
        Map<String, dynamic> studentData = {'Student Name': student['name']};
        final studentPerf = performanceSnapshot.docs.where((r) => r['studentId'] == student.id);

        for (var r in studentPerf) {
          studentData[r['topic']] = r['level'];
        }
        exportData.add(studentData);
      }

      if (exportData.isEmpty) throw 'No data found';

      if (context != null && context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Select Export Format'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    exportJsonToFile(exportData, '${className}_$subjectName', format: 'xlsx', context: context);
                  },
                  child: const Text('Excel (.xlsx)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    exportJsonToFile(exportData, '${className}_$subjectName', format: 'csv', context: context);
                  },
                  child: const Text('CSV (.csv)'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}