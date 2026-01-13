import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pdfprinting.dart';

class PdfPrintingPage extends StatefulWidget {
  final String classId;
  final String? preselectedSubjectId;

  const PdfPrintingPage({
    super.key, 
    required this.classId,
    this.preselectedSubjectId,
  });

  @override
  State<PdfPrintingPage> createState() => _PdfPrintingPageState();
}

class _PdfPrintingPageState extends State<PdfPrintingPage> {
  List<Map<String, dynamic>> students = [];
  Set<String> selectedStudents = {};
  String? selectedSubjectId = 'OVERALL';
  String searchQuery = '';
  List<Map<String, String>> subjects = [];

  @override
  void initState() {
    super.initState();
    selectedSubjectId = widget.preselectedSubjectId ?? 'OVERALL'; // use preselected
    fetchStudentsAndSubjects();
  }

  Future<void> fetchStudentsAndSubjects() async {
    final studentSnap = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .get();

    final subjectSnap = await FirebaseFirestore.instance
        .collection('subjects')
        .where('classId', isEqualTo: widget.classId)
        .get();

    setState(() {
      students = studentSnap.docs
          .map((s) => {'id': s.id, 'name': s['name']})
          .toList()
          ..sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase())); // sort alphabetically

      subjects = subjectSnap.docs
          .map((s) => {'id': s.id, 'name': s['name'].toString()})
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = searchQuery.isEmpty
        ? students
        : students
            .where((s) =>
                s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    final allSelected = selectedStudents.length == filteredStudents.length && filteredStudents.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate PDF'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ===== Subject Dropdown =====
           DropdownButton<String>(
              value: subjects.any((s) => s['id'] == selectedSubjectId) || selectedSubjectId == 'OVERALL'
                  ? selectedSubjectId
                  : 'OVERALL',
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: 'OVERALL',
                  child: Text('Overall Performance'),
                ),
                ...subjects.map((s) => DropdownMenuItem(
                      value: s['id'],
                      child: Text(s['name']!),
                    )),
              ],
              onChanged: (v) => setState(() => selectedSubjectId = v),
            ),
            const SizedBox(height: 12),

            // ===== Search Bar =====
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Student',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
            const SizedBox(height: 12),

            // ===== Select All Checkbox =====
            CheckboxListTile(
              title: const Text('Select All'),
              value: allSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    selectedStudents = filteredStudents.map((s) => s['id'].toString()).toSet();
                  } else {
                    selectedStudents.clear();
                  }
                });
              },
            ),
            const Divider(),

            // ===== Student List =====
            Expanded(
              child: ListView(
                children: filteredStudents.map((s) {
                  return CheckboxListTile(
                    title: Text(s['name']),
                    value: selectedStudents.contains(s['id']),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedStudents.add(s['id']);
                        } else {
                          selectedStudents.remove(s['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            // ===== Generate PDF Button =====
            ElevatedButton(
              onPressed: selectedStudents.isEmpty
                  ? null
                  : () {
                      final selected = students
                          .where((s) => selectedStudents.contains(s['id']))
                          .toList();

                      generatePdfForStudents(
                        students: selected,
                        classId: widget.classId,
                        selectedSubjectId: selectedSubjectId,
                      );
                    },
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
