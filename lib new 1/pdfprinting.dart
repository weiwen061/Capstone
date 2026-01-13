import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// TP levels used in the app
const List<String> tpLevels = ['TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'];

/// Generate PDFs for multiple students with optional search filtering
Future<void> generatePdfForStudents({
  required List<Map<String, dynamic>> students, // [{id: studentId, name: studentName}]
  required String classId,
  String? selectedSubjectId, // 'OVERALL' or subjectId
  String? searchQuery,       // optional search filter
}) async {
  final firestore = FirebaseFirestore.instance;
  final pdf = pw.Document();

  // =========================
  // Fetch subjects
  // =========================
  final subjectSnapshot = await firestore.collection('subjects').get();
  final Map<String, String> subjectMap = {
    for (var doc in subjectSnapshot.docs) doc.id: doc['name']
  };

  // =========================
  // Filter students by searchQuery
  // =========================
  final filteredStudents = searchQuery != null && searchQuery.isNotEmpty
      ? students.where((s) => s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList()
      : students;

  if (filteredStudents.isEmpty) {
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Center(
          child: pw.Text('No students match the search filter.'),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    return;
  }

  // =========================
  // Loop through students
  // =========================
  for (var student in filteredStudents) {
    final studentId = student['id'];
    final studentName = student['name'];

    // Fetch performance records for this student
    Query perfQuery = firestore
        .collection('performance')
        .where('studentId', isEqualTo: studentId);

    if (selectedSubjectId != null && selectedSubjectId != 'OVERALL') {
      perfQuery = perfQuery.where('subjectId', isEqualTo: selectedSubjectId);
    }

    final perfSnapshot = await perfQuery.get();

    if (perfSnapshot.docs.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Center(
            child: pw.Text('No performance records found for $studentName.'),
          ),
        ),
      );
      continue;
    }

    // Group records by subject
    final Map<String, List<QueryDocumentSnapshot>> subjectGroups = {};
    for (var doc in perfSnapshot.docs) {
      final subjectId = doc['subjectId'];
      subjectGroups.putIfAbsent(subjectId, () => []);
      subjectGroups[subjectId]!.add(doc);
    }

    // Build PDF page for this student
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          final List<pw.Widget> widgets = [];

          widgets.add(
            pw.Text(
              'Performance Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          );

          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Student: $studentName'));
          widgets.add(pw.SizedBox(height: 16));

          subjectGroups.forEach((subjectId, records) {
            final subjectName = subjectMap[subjectId] ?? 'Unknown Subject';

            widgets.add(
              pw.Text(
                'Subject: $subjectName',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: 6));

            widgets.add(
              pw.TableHelper.fromTextArray(
                headers: ['Topic', 'TP'],
                data: records
                    .map((r) => [
                          r['topic'],
                          r['level'],
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            );

            widgets.add(pw.SizedBox(height: 16));
          });

          return widgets;
        },
      ),
    );
  }

  // =========================
  // Print PDF
  // =========================
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

/// =========================
/// Wrapper for single student
/// =========================
Future<void> generatePdfForStudent({
  required String studentName,
  required String studentId,
  required String classId,
  String? selectedSubjectId,
}) async {
  await generatePdfForStudents(
    students: [
      {'id': studentId, 'name': studentName}
    ],
    classId: classId,
    selectedSubjectId: selectedSubjectId,
  );
}
