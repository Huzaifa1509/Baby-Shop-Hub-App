import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminProfileScreen extends StatefulWidget {
  final String userId;

  AdminProfileScreen({required this.userId});

  @override
  _AdmninProfileScreenState createState() => _AdmninProfileScreenState();
}
class _AdmninProfileScreenState extends State<AdminProfileScreen> {
  File? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('UserCollection').doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User data not found'));
          }
          var userDoc = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: _image == null
                            ? NetworkImage(userDoc['profile_pic'] ?? '')
                            : FileImage(_image!) as ImageProvider,
                        radius: 50,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildEditableField(
                  context,
                  'Username',
                  userDoc['name'] ?? 'N/A',
                  (value) {
                    FirebaseFirestore.instance.collection('UserCollection').doc(widget.userId).update({
                      'name': value,
                    });
                  },
                ),
                _buildEditableField(
                  context,
                  'Email',
                  userDoc['email'] ?? 'N/A',
                  (value) {
                    FirebaseFirestore.instance.collection('UserCollection').doc(widget.userId).update({
                      'email': value,
                    });
                  },
                ),
                _buildEditableField(
                  context,
                  'Delivery Address',
                  userDoc['delivery_address'] ?? 'N/A',
                  (value) {
                    FirebaseFirestore.instance.collection('UserCollection').doc(widget.userId).update({
                      'delivery_address': value,
                    });
                  },
                ),
                _buildEditableField(
                  context,
                  'Password',
                  userDoc['password'] ?? 'N/A',
                  (value) {
                    FirebaseFirestore.instance.collection('UserCollection').doc(widget.userId).update({
                      'password': value,
                    });
                  },
                  isPassword: true,
                ),
                
              ],
            ),
          );
        },
      ),
    );
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // Add functionality to upload image to Firestore and update the profile_pic field
      FirebaseFirestore.instance.collection('UserCollection').doc(widget.userId).update({
        'profile_pic': pickedFile.path, // Update with the URL after uploading the image
      });
    }
  }

  Widget _buildEditableField(BuildContext context, String label, String value, Function(String) onSave, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context, label, value, onSave, isPassword: isPassword);
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String label, String value, Function(String) onSave, {bool isPassword = false}) {
    final _controller = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: label),
            obscureText: isPassword,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(_controller.text);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}