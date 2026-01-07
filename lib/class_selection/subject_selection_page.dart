import 'package:flutter/material.dart';

class SubjectSelectionPage extends StatelessWidget {
  final String className;
  const SubjectSelectionPage({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subjects: $className")),
      body: const Center(child: Text("Subject list logic goes here.")),
    );
  }
}