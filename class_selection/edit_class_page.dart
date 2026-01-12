import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditClassPage extends StatefulWidget {
  final String? docId;        
  final String? existingName; 

  const EditClassPage({super.key, this.docId, this.existingName});

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Pre-fills the text field if you are editing an existing class
    _controller = TextEditingController(text: widget.existingName ?? "");
  }

  Future<void> _saveClass() async {
    if (_controller.text.isNotEmpty) {
      String customId = _controller.text; // Uses the text you typed as the Firebase ID

      if (widget.docId == null) {
        // ADD NEW: Creates a document where the ID is the Class Name
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(customId) 
            .set({
          'className': _controller.text,
          'createdAt': Timestamp.now(),
        });
      } else {
        // EDIT EXISTING: Updates the name of the existing document
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.docId)
            .update({
          'className': _controller.text,
        });
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? "Add New Class" : "Edit Class"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller, 
              decoration: const InputDecoration(labelText: "Class Name"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveClass, 
              child: const Text("Save Class"),
            ),
          ],
        ),
      ),
    );
  }
}