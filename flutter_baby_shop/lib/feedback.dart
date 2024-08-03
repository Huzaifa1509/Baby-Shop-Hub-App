import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackFormScreen extends StatefulWidget {  
  final String userId;

  FeedbackFormScreen({required this.userId});
  @override
  _FeedbackFormScreenState createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String email = _emailController.text;
      String message = _messageController.text;

      // Get the current highest ID
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('FeedbackSupport').get();
      int highestId = querySnapshot.docs.map((doc) => int.parse(doc.id)).fold(0, (prev, next) => next > prev ? next : prev);

      // Increment the ID by 1
      int newId = highestId + 1;

      await FirebaseFirestore.instance.collection('FeedbackSupport').doc(newId.toString()).set({
        'name': name,
        'email': email,
        'message': message,
        'user_id': widget.userId,
        'id': newId,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback submitted successfully!')));
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(labelText: 'Message'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your message';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitFeedback,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
