import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'logout.dart';
import 'csv_import.dart'; // <-- import your CSVtoJSONHelper

/// -------------------- MAIN --------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

/// -------------------- APP --------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Management',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ClassSelectionPage(),
    );
  }
}

/// -------------------- CLASS SELECTION PAGE --------------------
class ClassSelectionPage extends StatefulWidget {
  const ClassSelectionPage({super.key});

  @override
  State<ClassSelectionPage> createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ClassSelectionPage> {
  final TextEditingController _classController = TextEditingController();

  Future<void> _addClass() async {
    if (_classController.text.trim().isEmpty) return;

    final doc = FirebaseFirestore.instance.collection('classes').doc();

    await doc.set({
      'className': _classController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _classController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
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
                    controller: _classController,
                    decoration:
                        const InputDecoration(labelText: 'New Class Name'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addClass,
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .orderBy('className')
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final classes = snapshot.data!.docs;

                if (classes.isEmpty) {
                  return const Center(child: Text('No classes yet'));
                }

                return ListView.builder(
                  itemCount: classes.length,
                  itemBuilder: (_, index) {
                    final doc = classes[index];
                    return ListTile(
                      title: Text(doc['className']),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentManagementPage(
                              classId: doc.id,
                              className: doc['className'],
                            ),
                          ),
                        );
                      },
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

/// -------------------- STUDENT MANAGEMENT PAGE --------------------
class StudentManagementPage extends StatefulWidget {
  final String classId;
  final String className;

  const StudentManagementPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentManagementPage> createState() =>
      _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final TextEditingController _nameController = TextEditingController();

  /// ADD / EDIT STUDENT
  Future<void> _openStudentDialog({String? id, String? name}) async {
    _nameController.text = name ?? '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Add Student' : 'Edit Student'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Student Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) return;

              final ref = FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('students');

              if (id == null) {
                await ref.add({
                  'name': _nameController.text.trim(),
                  'nameLower': _nameController.text.trim().toLowerCase(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                await ref.doc(id).update({
                  'name': _nameController.text.trim(),
                  'nameLower': _nameController.text.trim().toLowerCase(),
                });
              }

              _nameController.clear();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

 /// DELETE STUDENT AND THEIR PERFORMANCE RECORDS
  Future<void> _deleteStudent(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Delete "$name" and all their performance records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1️⃣ Delete student document
      final studentRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(id);
      batch.delete(studentRef);

      // 2️⃣ Delete all performance records of this student
      final perfSnapshot = await FirebaseFirestore.instance
          .collection('performance')
          .where('classId', isEqualTo: widget.classId)
          .where('studentId', isEqualTo: id)
          .get();

      for (var doc in perfSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3️⃣ Commit batch
      await batch.commit();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $name and all their performance records')),
      );
    } catch (e) {
      debugPrint('Error deleting student and performance: $e');
    }
  }

  /// BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('students')
            .orderBy('nameLower')
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text('No students yet'));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (_, index) {
              final doc = students[index];
              return ListTile(
                title: Text(doc['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openStudentDialog(
                        id: doc.id,
                        name: doc['name'],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteStudent(doc.id, doc['name']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show choice: single student or import CSV
          final choice = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Add Students'),
              content: const Text('Choose an option:'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'single'),
                  child: const Text('Add Single Student'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'csv'),
                  child: const Text('Import CSV/Excel'),
                ),
              ],
            ),
          );

          if (choice == 'single') {
            _openStudentDialog();
          } else if (choice == 'csv') {
            CSVandExcelHelper.importStudents(
              classId: widget.classId,
              context: context,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
