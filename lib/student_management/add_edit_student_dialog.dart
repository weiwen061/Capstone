import 'package:flutter/material.dart';
import 'student.dart';

class AddEditStudentDialog extends StatefulWidget {
  final Student? student;

  const AddEditStudentDialog({super.key, this.student});

  @override
  State<AddEditStudentDialog> createState() => _AddEditStudentDialogState();
}

class _AddEditStudentDialogState extends State<AddEditStudentDialog> {
  late TextEditingController nameController;
  late TextEditingController idController;
  late TextEditingController classController;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.student?.name ?? '');
    idController =
        TextEditingController(text: widget.student?.studentId ?? '');
    classController =
        TextEditingController(text: widget.student?.studentClass ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null
          ? 'Add Student'
          : 'Edit Student'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Student Name'),
          ),
          TextField(
            controller: idController,
            decoration: const InputDecoration(labelText: 'Student ID'),
          ),
          TextField(
            controller: classController,
            decoration: const InputDecoration(labelText: 'Class / Year'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final student = Student(
              name: nameController.text,
              studentId: idController.text,
              studentClass: classController.text,
            );
            Navigator.pop(context, student);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
