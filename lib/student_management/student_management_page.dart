import 'package:flutter/material.dart';
import 'student.dart';
import 'student_list.dart';
import 'add_edit_student_dialog.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() =>
      _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final List<Student> _students = [
    Student(
      name: 'Ali Ahmad',
      studentId: 'P1023',
      studentClass: 'Year 5',
    ),
    Student(
      name: 'Siti Nur',
      studentId: 'P1048',
      studentClass: 'Year 4',
    ),
  ];

  void _addStudent(Student student) {
    setState(() {
      _students.add(student);
    });
  }

  void _editStudent(int index, Student student) {
    setState(() {
      _students[index] = student;
    });
  }

  Future<void> _openAddDialog() async {
    final newStudent = await showDialog<Student>(
      context: context,
      builder: (_) => const AddEditStudentDialog(),
    );

    if (newStudent != null) {
      _addStudent(newStudent);
    }
  }

  Future<void> _openEditDialog(int index) async {
    final editedStudent = await showDialog<Student>(
      context: context,
      builder: (_) =>
          AddEditStudentDialog(student: _students[index]),
    );

    if (editedStudent != null) {
      _editStudent(index, editedStudent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
      ),
      body: StudentList(
        students: _students,
        onEdit: _openEditDialog,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
