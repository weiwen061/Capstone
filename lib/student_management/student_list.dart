import 'package:flutter/material.dart';
import 'student.dart';

class StudentList extends StatelessWidget {
  final List<Student> students;
  final void Function(int index) onEdit;

  const StudentList({
    super.key,
    required this.students,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(student.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student ID: ${student.studentId}'),
                Text('Class: ${student.studentClass}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => onEdit(index),
            ),
          ),
        );
      },
    );
  }
}
