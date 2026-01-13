import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_performance_app/login.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'studentmanagement.dart';
import 'subjectselection.dart';
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
      title: 'Student Performance App',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const LoginPage(),
    );
  }
}

/* ================= CLASS SELECTION PAGE ================= */
class ClassSelectionPage extends StatelessWidget {
  const ClassSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final uid = authSnapshot.data!.uid;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .where('owner', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, classSnapshot) {
            if (!classSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final classes = classSnapshot.data!.docs;
            final totalClasses = classes.length;

            return Scaffold(
              appBar: AppBar(
                title: const Text("Class Selection"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => logout(context),
                  ),
                ],
              ),
              body: classes.isEmpty
                  ? Center(
                      child: ElevatedButton(
                        child: const Text("Add First Class"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditClassPage(),
                            ),
                          );
                        },
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // SCHOOL LOGO
                              Image.asset('assets/sksi.jpg', height: 70),
                              const SizedBox(height: 8),
                              const Text(
                                'SEK. KEB. SAUJANA INDAH',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // SUMMARY CARDS
                              Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.menu_book,
                                                size: 40, color: Colors.orange),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$totalClasses',
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const Text(
                                              'Total Classes',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StreamBuilder<List<int>>(
                                      stream: _studentsCountStream(classes),
                                      builder: (context, snapshot) {
                                        int totalStudents = 0;
                                        if (snapshot.hasData) {
                                          totalStudents =
                                              snapshot.data!.fold(0, (a, b) => a + b);
                                        }

                                        return Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              children: [
                                                const Icon(Icons.people,
                                                    size: 40, color: Colors.blue),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '$totalStudents',
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                const Text(
                                                  'Total Students',
                                                  style:
                                                      TextStyle(color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: classes.map((doc) {
                              final classId = doc.id;
                              final className = doc['className'];

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(className),
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (_) {
                                        return Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                className,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.people),
                                                label:
                                                    const Text("Student Management"),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          StudentManagementPage(
                                                        classId: classId,
                                                        className: className,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.book),
                                                label:
                                                    const Text("Subject Selection"),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          SubjectSelectionPage(
                                                        classId: classId,
                                                        className: className,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditClassPage(
                                                docId: classId,
                                                existingName: className,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () =>
                                            _confirmDelete(context, classId),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
              floatingActionButton: classes.isNotEmpty
                  ? FloatingActionButton(
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditClassPage(),
                          ),
                        );
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  // ------------------ Delete Class ------------------
  void _confirmDelete(BuildContext context, String classId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Class"),
        content: const Text(
            "Are you sure you want to delete this class and all its students, subjects, and performance records?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();

              try {
                // Delete students
                final studentsSnap = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('students')
                    .get();
                for (var doc in studentsSnap.docs) {
                  batch.delete(doc.reference);
                }

                // Delete subjects
                final subjectsSnap = await FirebaseFirestore.instance
                    .collection('subjects')
                    .where('classId', isEqualTo: classId)
                    .get();
                for (var doc in subjectsSnap.docs) {
                  batch.delete(doc.reference);
                }

                // Delete performance
                final performanceSnap = await FirebaseFirestore.instance
                    .collection('performance')
                    .where('classId', isEqualTo: classId)
                    .get();
                for (var doc in performanceSnap.docs) {
                  batch.delete(doc.reference);
                }

                // Delete class itself
                final classRef =
                    FirebaseFirestore.instance.collection('classes').doc(classId);
                batch.delete(classRef);

                await batch.commit();
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Class deleted successfully")),
                );
              } catch (e) {
                debugPrint("Error deleting class: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete class: $e")),
                  );
                }
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ Student Count Stream ------------------
  Stream<List<int>> _studentsCountStream(
      List<QueryDocumentSnapshot> classes) async* {
    while (true) {
      final counts = <int>[];
      for (var doc in classes) {
        final snap = await FirebaseFirestore.instance
            .collection('classes')
            .doc(doc.id)
            .collection('students')
            .snapshots()
            .first;
        counts.add(snap.docs.length);
      }
      yield counts;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
/* ================= ADD / EDIT CLASS PAGE ================= */

class EditClassPage extends StatefulWidget {
  final String? docId;
  final String? existingName;

  const EditClassPage({super.key, this.docId, this.existingName});

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingName ?? '');
  }

  Future<void> _saveClass() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    if (widget.docId == null) {
      await FirebaseFirestore.instance.collection('classes').add({
        'className': name,
        'owner': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': Timestamp.now(),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.docId)
          .update({'className': name});
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Add New Class' : 'Edit Class'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _saveClass,
              child: const Text('Save Class'),
            ),
          ],
        ),
      ),
    );
  }
}
