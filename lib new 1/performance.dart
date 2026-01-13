import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'Classselection.dart';
import 'logout.dart';
import 'printingpage.dart';
import 'dart:async';
import 'analysis.dart';
import 'excel_export.dart';

final List<String> tpLevels = ['TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'];

// ===== Helper functions for Analysis =====
int tpIndex(String level) => ['TP1','TP2','TP3','TP4','TP5','TP6'].indexOf(level) + 1;

// Compute average TP per subject for a student
// Add this inside _PerformanceAnalysisPageState (or outside the class if you prefer)
Map<String, double> computeSubjectAverageTP(List<Map<String, dynamic>> records) {
  if (records.isEmpty) return {};

  // Group by subject
  Map<String, List<double>> subjectMap = {};
  for (var r in records) {
    final subject = r['subjectId'] ?? 'Unknown';
    final level = r['level'] ?? 'TP1';
    final tpNum = tpLevels.indexOf(level) + 1; // TP1 -> 1, TP6 -> 6
    subjectMap.putIfAbsent(subject, () => []);
    subjectMap[subject]!.add(tpNum.toDouble());
  }

  // Compute average per subject
  Map<String, double> subjectAvg = {
    for (var e in subjectMap.entries)
      e.key: e.value.reduce((a, b) => a + b) / e.value.length
  };

  return subjectAvg;
}

// Compute average TP per topic for a subject of a student
Map<String, double> computeTopicAverageTP(List<Map<String, dynamic>> studentRecords, String subjectId) {
  Map<String, List<int>> topicMap = {};
  for (var r in studentRecords) {
    if (r['subjectId'] != subjectId) continue;
    final topic = r['topic'] as String;
    final level = r['level'] as String;
    topicMap.putIfAbsent(topic, () => []);
    topicMap[topic]!.add(tpIndex(level));
  }

  return {
    for (var e in topicMap.entries)
      e.key: e.value.reduce((a,b)=>a+b)/e.value.length
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Performance',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ClassSelectionPage(),
    );
  }
}

/* =========================================================
   PERFORMANCE CHOICE PAGE
   ========================================================= */

class PerformanceChoicePage extends StatelessWidget {
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;

  const PerformanceChoicePage({
    super.key,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== View Performance =====
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove_red_eye),
              label: const Text('View Performance'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerformancePage(
                      classId: classId,
                      className: className,
                      selectedSubjectId: subjectId,
                      selectedSubjectName: subjectName,
                      editMode: false,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // ===== Edit Performance =====
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Performance'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerformancePage(
                      classId: classId,
                      className: className,
                      selectedSubjectId: subjectId,
                      selectedSubjectName: subjectName,
                      editMode: true,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // ===== Analysis =====
            ElevatedButton.icon(
              icon: const Icon(Icons.donut_small),
              label: const Text('Analysis'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerformanceAnalysisPage(
                      classId: classId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // ===== Print PDF =====
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Print PDF'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfPrintingPage(
                      classId: classId,
                      preselectedSubjectId: subjectId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   PERFORMANCE PAGE
   ========================================================= */

class PerformancePage extends StatefulWidget {
  final String classId;
  final String className;
  final String selectedSubjectId;
  final String selectedSubjectName;
  final bool editMode;

  const PerformancePage({
    super.key,
    required this.classId,
    required this.className,
    required this.selectedSubjectId,
    required this.selectedSubjectName,
    required this.editMode,
  });

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final TextEditingController _topicController = TextEditingController();
  final List<String> tpLevels = ['TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'];
  String? currentViewSubjectId;
  String searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    currentViewSubjectId = widget.selectedSubjectId;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: Text(widget.editMode
      ? '${widget.selectedSubjectName} - Edit Performance'
      : 'View Performance'),
  actions: [
    // ======= LOGOUT BUTTON =======
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => logout(context),
    ),
    //Show export in View Mode
    if (!widget.editMode)
      IconButton(
        icon: const Icon(Icons.file_download, color: Colors.green),
        tooltip: 'Export Performance',
        onPressed: () {
          String exportSubjectName;
          if (currentViewSubjectId == null ||
              currentViewSubjectId == 'OVERALL') {
            exportSubjectName = 'Overall';
          } else {
            exportSubjectName = widget.selectedSubjectName;
          }
          ExcelExportHelper.exportPerformanceFromFirestore(
            widget.classId,
            widget.className,
            exportSubjectName,
            context: context,
          );
        },
      ),
    ],
  ),

      body: Column(
        children: [
          if (!widget.editMode) _buildDropdown(),
          _buildSearchBar(),
          Expanded(
            child: widget.editMode
                ? _buildEditTableOptimized()
                : _buildStudentListOptimized(),
          ),
           ],
         ),
       );
     }
              
  // ==================== DROPDOWN ====================
  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .where('classId', isEqualTo: widget.classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final items = [
            const DropdownMenuItem(
              value: 'OVERALL',
              child: Text('Overall Performance'),
            ),
            ...snapshot.data!.docs.map(
              (s) => DropdownMenuItem(
                value: s.id,
                child: Text(s['name']),
              ),
            ),
          ];

          final valueExists =
              items.any((item) => item.value == currentViewSubjectId);

          return DropdownButton<String>(
            value: valueExists ? currentViewSubjectId : 'OVERALL',
            isExpanded: true,
            items: items,
            onChanged: (v) => setState(() => currentViewSubjectId = v),
          );
        },
      ),
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Search Student',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            setState(() => searchQuery = v);
          });
        },
      ),
    );
  }

  // ==================== VIEW MODE STUDENT LIST (Optimized) ====================
  Widget _buildStudentListOptimized() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .snapshots(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData)
          return const Center(child: CircularProgressIndicator());

        final students = studentSnap.data!.docs
            .where((s) =>
                s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
            .toList()
            ..sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));

        if (currentViewSubjectId == null || currentViewSubjectId == 'OVERALL') {
  // OVERALL mode
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('performance')
        .where('classId', isEqualTo: widget.classId)
        .snapshots(),
    builder: (context, perfSnap) {
      if (!perfSnap.hasData)
        return const Center(child: CircularProgressIndicator());
      final records = perfSnap.data!.docs;

      // Pre-build map: studentId -> subjectId -> records
      final Map<String, Map<String, List<QueryDocumentSnapshot>>> studentMap = {};
      for (var r in records) {
        final sid = r['studentId'];
        final subId = r['subjectId'];
        studentMap[sid] ??= {};
        studentMap[sid]![subId] ??= [];
        studentMap[sid]![subId]!.add(r);
      }

      return ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final sRecords = studentMap[student.id] ?? {};

          return Card(
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                      child: Text(student['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold))),
                ],
              ),
              children: sRecords.entries.map((entry) {
                final subId = entry.key;
                final subRecords = entry.value;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subId)
                      .snapshots(),
                  builder: (context, subSnap) {
                    if (!subSnap.hasData) return const SizedBox.shrink();
                    final subjectName = subSnap.data!['name'];

                    // Compute subject Average TP
                    double avg = subRecords.isNotEmpty
                        ? subRecords
                                .map((e) => tpLevels.indexOf(e['level']) + 1)
                                .reduce((a, b) => a + b) /
                            subRecords.length
                        : 0.0;

                    // Build list of topics under this subject
                    final topicWidgets = subRecords.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ListTile(
                          title: Text(r['topic']),
                          trailing: Text(r['level']),
                        ),
                      );
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(subjectName),
                          subtitle: Text('Average TP: ${avg.toStringAsFixed(2)}'),
                        ),
                        ...topicWidgets, // show all topics under this subject
                      ],
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      );
    },
  );
}
        // Specific subject mode
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('performance')
              .where('subjectId', isEqualTo: currentViewSubjectId)
              .snapshots(),
          builder: (context, perfSnap) {
            if (!perfSnap.hasData)
              return const Center(child: CircularProgressIndicator());
            final allRecords = perfSnap.data!.docs;
            final allTopics = allRecords.map((r) => r['topic'].toString()).toSet().toList();
            if (allTopics.isEmpty) allTopics.add('No Topic');

            // Build map for O(1) lookup
            final Map<String, Map<String, QueryDocumentSnapshot>> perfMap = {};
            for (var r in allRecords) {
              perfMap[r['studentId']] ??= {};
              perfMap[r['studentId']]![r['topic']] = r;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Student')),
                    ...allTopics.map((t) => DataColumn(label: Text(t))),
                  ],
                  rows: List.generate(students.length, (index) {
                    final student = students[index];
                    final studentPerf = perfMap[student.id] ?? {};

                    return DataRow(
                      cells: [
                        DataCell(Row(
                          children: [
                            Expanded(child: Text(student['name'])),
                          ],
                        )),
                        ...allTopics.map((topic) {
                          final record = studentPerf[topic];
                          final tp = record != null ? record['level'] : 'N/A';
                          return DataCell(Text(tp));
                        }),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== EDIT MODE TABLE (Optimized) ====================
  Widget _buildEditTableOptimized() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .snapshots(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData) return const Center(child: CircularProgressIndicator());

        // NEW CORRECTED CODE
        final students = studentSnap.data!.docs
            .where((s) => s['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase())) // This adds the search functionality
            .toList()
          ..sort((a, b) => a['name']
              .toString()
              .toLowerCase()
              .compareTo(b['name'].toString().toLowerCase()));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('performance')
              .where('classId', isEqualTo: widget.classId)
              .where('subjectId', isEqualTo: widget.selectedSubjectId)
              .snapshots(),
          builder: (context, perfSnap) {
            if (!perfSnap.hasData) return const Center(child: CircularProgressIndicator());

            final records = perfSnap.data!.docs;
            final topics = records.map((e) => e['topic'].toString()).toSet().toList();
            if (topics.isEmpty) topics.add('No Topic');

            final Map<String, Map<String, QueryDocumentSnapshot>> perfMap = {};
            for (var r in records) {
              perfMap[r['studentId']] ??= {};
              perfMap[r['studentId']]![r['topic']] = r;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Student')),
                    ...topics.map((t) => DataColumn(
                          label: Row(
                            children: [
                              Text(t),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () => editTopicDialog(t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 16),
                                onPressed: () => deleteTopic(t),
                              ),
                            ],
                          ),
                        )),
                    const DataColumn(label: Icon(Icons.add)),
                  ],
                  rows: List.generate(students.length, (index) {
                    final student = students[index];
                    final studentPerf = perfMap[student.id] ?? {};

                    return DataRow(
                      cells: [
                        DataCell(Text(student['name'])),
                        ...topics.map((topic) {
                          final record = studentPerf[topic];
                          String currentTP = tpLevels.first;
                          if (record != null && tpLevels.contains(record['level'])) {
                            currentTP = record['level'];
                          }

                          return DataCell(StatefulBuilder(
                            builder: (context, setCellState) => DropdownButton<String>(
                              value: currentTP,
                              items: tpLevels
                                  .map((tp) => DropdownMenuItem(value: tp, child: Text(tp)))
                                  .toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                setCellState(() => currentTP = v);

                                if (record == null) {
                                  await FirebaseFirestore.instance.collection('performance').add({
                                    'studentId': student.id,
                                    'classId': widget.classId,
                                    'subjectId': widget.selectedSubjectId,
                                    'topic': topic,
                                    'level': v,
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('performance')
                                      .doc(record.id)
                                      .update({'level': v});
                                }
                              },
                            ),
                          ));
                        }),
                        DataCell(IconButton(icon: const Icon(Icons.add), onPressed: addTopicDialog)),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== ADD TOPIC ====================
  void addTopicDialog() {
    _topicController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Evaluated Topic'),
        content: TextField(
          controller: _topicController,
          decoration: const InputDecoration(
            labelText: 'Topic',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final topic = _topicController.text.trim();
              if (topic.isEmpty) return;

              Navigator.pop(context);

              final studentsSnapshot = await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('students')
                  .get();

              final batch = FirebaseFirestore.instance.batch();

              for (var s in studentsSnapshot.docs) {
                final docRef = FirebaseFirestore.instance.collection('performance').doc();
                batch.set(docRef, {
                  'studentId': s.id,
                  'classId': widget.classId,
                  'subjectId': widget.selectedSubjectId,
                  'topic': topic,
                  'level': tpLevels.first,
                });
              }

              await batch.commit();
              if (!mounted) return;
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ==================== EDIT TOPIC ====================
  void editTopicDialog(String oldTopic) {
    _topicController.text = oldTopic;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Topic'),
        content: TextField(
          controller: _topicController,
          decoration: const InputDecoration(
            labelText: 'Topic',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTopic = _topicController.text.trim();
              if (newTopic.isEmpty || newTopic == oldTopic) return;

              Navigator.pop(context);

              final querySnapshot = await FirebaseFirestore.instance
                  .collection('performance')
                  .where('classId', isEqualTo: widget.classId)
                  .where('subjectId', isEqualTo: widget.selectedSubjectId)
                  .where('topic', isEqualTo: oldTopic)
                  .get();

              if (querySnapshot.docs.isEmpty) return;

              final batch = FirebaseFirestore.instance.batch();

              for (var d in querySnapshot.docs) {
                batch.update(d.reference, {'topic': newTopic});
              }

              await batch.commit();
              if (!mounted) return;
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==================== DELETE TOPIC ====================
  void deleteTopic(String topic) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('performance')
          .where('classId', isEqualTo: widget.classId)
          .where('subjectId', isEqualTo: widget.selectedSubjectId)
          .where('topic', isEqualTo: topic)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (var d in querySnapshot.docs) {
        batch.delete(d.reference);
      }

      await batch.commit();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error deleting topic: $e');
    }
  }
}
