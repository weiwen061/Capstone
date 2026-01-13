import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'classselection.dart';
import 'performance.dart';
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
   SUBJECT SELECTION PAGE
   ========================================================= */

class SubjectSelectionPage extends StatefulWidget {
  final String classId;
  final String className;

  const SubjectSelectionPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<SubjectSelectionPage> createState() => _SubjectSelectionPageState();
}

class _SubjectSelectionPageState extends State<SubjectSelectionPage> {
  final TextEditingController _newSubjectController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    _newSubjectController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
       ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubjectController,
                    decoration: const InputDecoration(
                      labelText: 'Add new subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    final subjectName = _newSubjectController.text.trim();
                    if (subjectName.isEmpty) return;

                    await FirebaseFirestore.instance.collection('subjects').add({
                      'name': subjectName,
                      'classId': widget.classId,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    _newSubjectController.clear();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subjects')
                  .where('classId', isEqualTo: widget.classId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final subjects = snapshot.data!.docs
                  ..sort((a, b) =>
                      a['name'].toString().compareTo(b['name'].toString()));

                if (subjects.isEmpty) {
                  return const Center(child: Text('No subjects yet'));
                }

                return ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final doc = subjects[index];
                    final id = doc.id;

                    _controllers.putIfAbsent(
                      id,
                      () => TextEditingController(text: doc['name']),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          doc['name'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PerformanceChoicePage(
                                classId: widget.classId,
                                className: widget.className,
                                subjectId: id,
                                subjectName: doc['name'],
                              ),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title:
                                        const Text('Edit Subject Name'),
                                    content: TextField(
                                      controller: _controllers[id],
                                      decoration:
                                          const InputDecoration(
                                              border:
                                                  OutlineInputBorder()),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final newName =
                                              _controllers[id]!
                                                  .text
                                                  .trim();
                                          if (newName.isNotEmpty) {
                                            await FirebaseFirestore
                                                .instance
                                                .collection('subjects')
                                                .doc(id)
                                                .update(
                                                    {'name': newName});
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Subject?'),
                                    content: Text('Delete ${doc['name']} and all related performance records?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                try {
                                  final batch = FirebaseFirestore.instance.batch();

                                  // 1️⃣ Delete the subject document
                                  final subjectRef = FirebaseFirestore.instance.collection('subjects').doc(id);
                                  batch.delete(subjectRef);

                                  // 2️⃣ Delete all performance records for this subject
                                  final perfSnapshot = await FirebaseFirestore.instance
                                      .collection('performance')
                                      .where('classId', isEqualTo: widget.classId)
                                      .where('subjectId', isEqualTo: id)
                                      .get();

                                  for (var doc in perfSnapshot.docs) {
                                    batch.delete(doc.reference);
                                  }

                                  // 3️⃣ Commit batch
                                  await batch.commit();
                                  _controllers.remove(id);

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${doc['name']} and its performance records deleted')),
                                  );
                                } catch (e) {
                                  debugPrint('Error deleting subject and performance: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
