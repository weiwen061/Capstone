import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'logout.dart';

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
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                await ref.doc(id).update({
                  'name': _nameController.text.trim(),
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

  /// DELETE STUDENT
  Future<void> _deleteStudent(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Delete "$name"?'),
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

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(id)
          .delete();
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
            .orderBy('name')
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
        onPressed: () => _openStudentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
