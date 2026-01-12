import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login.dart';
import '../auth/logout.dart';
import '../student_management/studentmanagement.dart';
import '../subject_selection/subjectselection.dart';


class ClassSelectionPage extends StatefulWidget {
  const ClassSelectionPage({super.key});

  @override
  State<ClassSelectionPage> createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ClassSelectionPage> {
  final Stream<QuerySnapshot> _classesStream = FirebaseFirestore.instance
      .collection('classes')
      .orderBy('className')
      .snapshots();
  
  final Stream<QuerySnapshot> _allStudentsStream = FirebaseFirestore.instance
      .collection('students')
      .snapshots();

  // --- ADD NEW CLASS ---
  void _showAddClassDialog() {
    final TextEditingController classController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Class'),
        content: TextField(
          controller: classController,
          decoration: const InputDecoration(hintText: "Enter Class Name (e.g., 5 Anggerik)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (classController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('classes').add({
                  'className': classController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // --- EDIT CLASS NAME ---
  void _editClass(String docId, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Class Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(docId)
                    .update({'className': controller.text.trim()});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- DELETE CLASS ---
  void _deleteClass(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Class?"),
        content: const Text("Are you sure? This will delete the class permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('classes').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --- SHOW BOTTOM MENU ---
  void _showClassOptions(BuildContext context, String classId, String className) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                className,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.people, color: Colors.deepPurple),
                title: const Text('Student Management'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentManagementPage(
                        className: className,
                        classId: classId,
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: const Text('Subject Selection'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => SubjectSelectionPage(
                        classId: classId, 
                        className: className
                      )
                    )
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- SCHOOL LOGO SECTION ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Image.asset('assets/Sekolah_Kebangsaan_Saujana_Indah.jpg', height: 80),
                  const SizedBox(height: 10),
                  const Text(
                    "SEK. KEB. SAUJANA INDAH",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00008B)),
                  )
                ],
              ),
            ),

            // --- STATS SECTION ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _allStudentsStream,
                builder: (context, studentSnapshot) {
                  int totalStudents = 0;
                  if (studentSnapshot.hasData) {
                    totalStudents = studentSnapshot.data!.docs.length;
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _classesStream,
                    builder: (context, classSnapshot) {
                      int totalClasses = 0;
                      if (classSnapshot.hasData) {
                        totalClasses = classSnapshot.data!.docs.length;
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Total Classes", 
                              totalClasses.toString(), 
                              Icons.class_, 
                              Colors.orange
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              "Total Students", 
                              totalStudents.toString(), 
                              Icons.groups, 
                              Colors.blue
                            ),
                          ),
                        ],
                      );
                    }
                  );
                }
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Your Classes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            // --- CLASS LIST ---
            StreamBuilder<QuerySnapshot>(
              stream: _classesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading classes'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No classes found. Tap + to add one.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var document = snapshot.data!.docs[index];
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                    String className = data['className'] ?? 'Unknown Class';
                    String docId = document.id;

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          className,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editClass(docId, className),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteClass(docId),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showClassOptions(context, docId, className);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}