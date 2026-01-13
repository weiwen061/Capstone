import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Only needed for Mobile/Desktop
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show File;
import 'dart:typed_data';

// Excel package
import 'package:excel/excel.dart';

/// CSV / Excel to JSON Import Helper
class CSVandExcelHelper {
  /// Import students from CSV or Excel and save to subcollection directly
  static Future<void> importStudents({
    required String classId,
    required BuildContext context,
  }) async {
    try {
      // Pick CSV or XLSX file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: kIsWeb, // required for web
      );

      if (result == null) return; // user canceled

      String fileName = result.files.single.name;
      String fileExtension = fileName.split('.').last.toLowerCase();

      List<List<dynamic>> rows = [];

      if (fileExtension == 'csv') {
        // ---------------- CSV ----------------
        String csvContent;

        if (kIsWeb) {
          csvContent = String.fromCharCodes(result.files.single.bytes!);
        } else {
          final path = result.files.single.path!;
          csvContent = await File(path).readAsString();
        }

        rows = const CsvToListConverter().convert(csvContent);
      } else if (fileExtension == 'xlsx') {
        // ---------------- XLSX ----------------
        Uint8List bytes;

        if (kIsWeb) {
          bytes = result.files.single.bytes!;
        } else {
          final path = result.files.single.path!;
          bytes = await File(path).readAsBytes();
        }

        final excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            if (row.isNotEmpty) rows.add(row.map((e) => e?.value).toList());
          }
        }
      } else {
        throw 'Unsupported file type';
      }

      // ---------------- Save to students subcollection ----------------
      final studentsRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students');

      int addedCount = 0;
      for (var row in rows) {
        if (row.isEmpty || row[0] == null) continue;
        await studentsRef.add({
          'name': row[0].toString().trim(),
          'nameLower': row[0].toString().trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        addedCount++;
      }

      if (addedCount == 0) throw 'No valid student names found in the file.';

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$addedCount students imported successfully!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing file: $e')),
      );
    }
  }
}
