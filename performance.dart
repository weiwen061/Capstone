import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'Classselection.dart';
import 'logout.dart';

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
          children: [
            ElevatedButton(
              child: const Text('View Performance'),
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
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Edit Performance'),
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

  @override
  void initState() {
    super.initState();
    currentViewSubjectId = widget.selectedSubjectId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMode
              ? '${widget.selectedSubjectName} - Edit Performance'
              : 'View Performance',),
          actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
       ),
      
      body: Column(
        children: [
          if (!widget.editMode) _buildDropdown(),
          _buildSearchBar(),
          Expanded(
            child: widget.editMode ? _buildEditTable() : _buildStudentList(),
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

          final valueExists = items.any((item) => item.value == currentViewSubjectId);

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
        onChanged: (v) => setState(() => searchQuery = v),
      ),
    );
  }

  // ==================== VIEW MODE STUDENT LIST ====================
  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .snapshots(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData) return const Center(child: CircularProgressIndicator());

        final students = studentSnap.data!.docs
            .where((s) =>
                s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
            .toList()
          ..sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

        if (currentViewSubjectId == null || currentViewSubjectId == 'OVERALL') {
          // Overall: show subjects per student
          return ListView(
            children: students.map((student) {
              return Card(
                child: ExpansionTile(
                  title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: currentViewSubjectId == 'OVERALL'
                  ? null // hide ID for Overall
                  : Text('ID: ${student.id}'),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('performance')
                          .where('studentId', isEqualTo: student.id)
                          .snapshots(),
                      builder: (context, perfSnap) {
                        if (!perfSnap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final records = perfSnap.data!.docs;

                        final subjectsMap = <String, List<QueryDocumentSnapshot>>{};
                        for (var r in records) {
                          final subId = r['subjectId'];
                          subjectsMap[subId] ??= [];
                          subjectsMap[subId]!.add(r);
                        }

                        return Column(
                          children: subjectsMap.entries.map((entry) {
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

                                double avg = 0;
                                if (subRecords.isNotEmpty) {
                                  avg = subRecords
                                          .map((e) => tpLevels.indexOf(e['level']) + 1)
                                          .reduce((a, b) => a + b) /
                                      subRecords.length;
                                }

                                return ListTile(
                                  title: Text(subjectName),
                                  subtitle: Text('Overall TP: ${avg.toStringAsFixed(2)}'),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }

        // Selected subject → show all topics horizontally
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('performance')
              .where('subjectId', isEqualTo: currentViewSubjectId)
              .snapshots(),
          builder: (context, perfSnap) {
            if (!perfSnap.hasData) return const Center(child: CircularProgressIndicator());

            final allRecords = perfSnap.data!.docs;
            final allTopics = allRecords.map((r) => r['topic'].toString()).toSet().toList();
            if (allTopics.isEmpty) allTopics.add('No Topic');

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Student')),
                    ...allTopics.map((t) => DataColumn(label: Text(t))),
                  ],
                  rows: students.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(Text(student['name'])),
                        ...allTopics.map((topic) {
                          QueryDocumentSnapshot? record;
                          try {
                            record = allRecords.firstWhere(
                              (r) =>
                                  r['studentId'] == student.id &&
                                  r['topic'] == topic,
                            );
                          } catch (_) {
                            record = null;
                          }
                          final tp = record != null ? record['level'] : 'N/A';
                          return DataCell(Text(tp));
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== EDIT MODE TABLE ====================
  Widget _buildEditTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .snapshots(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData) return const Center(child: CircularProgressIndicator());

        final students = studentSnap.data!.docs
          ..sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

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

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Student')),
                    ...topics.map(
                      (t) => DataColumn(
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
                      ),
                    ),
                    const DataColumn(label: Icon(Icons.add)),
                  ],
                  rows: students.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(Text(student['name'])),
                        ...topics.map((topic) {
                          QueryDocumentSnapshot? record;
                          try {
                            record = records.firstWhere(
                              (r) =>
                                  r['studentId'] == student.id &&
                                  r['topic'] == topic,
                            );
                          } catch (_) {
                            record = null;
                          }

                          String currentTP = tpLevels.first;
                          if (record != null && tpLevels.contains(record['level'])) {
                            currentTP = record['level'];
                          }

                          return DataCell(
                            DropdownButton<String>(
                              value: currentTP,
                              items: tpLevels
                                  .map((tp) => DropdownMenuItem(value: tp, child: Text(tp)))
                                  .toList(),
                              onChanged: (v) async {
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
                          );
                        }),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: addTopicDialog,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final topic = _topicController.text.trim();
              if (topic.isEmpty) return;

              final students = await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('students')
                  .get();

              for (var s in students.docs) {
                await FirebaseFirestore.instance.collection('performance').add({
                  'studentId': s.id,
                  'classId': widget.classId,
                  'subjectId': widget.selectedSubjectId,
                  'topic': topic,
                  'level': tpLevels.first,
                });
              }

              if (!mounted) return; // stop if disposed
              Navigator.pop(context); // close dialog first
              if (!mounted) return;
              setState(() {}); // update UI safely
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ==================== EDIT TOPIC ====================
  void editTopicDialog(String oldTopic) {
    _topicController.text = oldTopic; // pre-fill old topic
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
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTopic = _topicController.text.trim();
              if (newTopic.isEmpty || newTopic == oldTopic) return;

              final docs = await FirebaseFirestore.instance
                  .collection('performance')
                  .where('classId', isEqualTo: widget.classId)
                  .where('subjectId', isEqualTo: widget.selectedSubjectId)
                  .where('topic', isEqualTo: oldTopic)
                  .get();

              for (var d in docs.docs) {
                await FirebaseFirestore.instance
                    .collection('performance')
                    .doc(d.id)
                    .update({'topic': newTopic});
              }

              if (!mounted) return;
              Navigator.pop(context);
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
    final docs = await FirebaseFirestore.instance
        .collection('performance')
        .where('classId', isEqualTo: widget.classId)
        .where('subjectId', isEqualTo: widget.selectedSubjectId)
        .where('topic', isEqualTo: topic)
        .get();

    for (var d in docs.docs) {
      await FirebaseFirestore.instance.collection('performance').doc(d.id).delete();
    }

    if (!mounted) return;
    setState(() {});
  }
}
