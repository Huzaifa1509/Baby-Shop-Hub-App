import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'order_product_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
                SizedBox(height: 20),
                Text(
                  'My Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(child: _buildOrderHistory(widget.userId)),
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

  Widget _buildOrderHistory(String userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('OrderCollection')
        .where('user_id', isEqualTo: userId)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error fetching orders'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('No orders found'));
      }

      var orders = snapshot.data!.docs;

      return ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          var order = orders[index];
          return Card(
            child: ListTile(
              title: Text(order['address'] ?? 'No Address'),
              subtitle: Text('Total Amount: ' + (order['total_amount']?.toString() ?? '0')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(order['status'] ?? 'Unknown'),
                  IconButton(
                    icon: Icon(Icons.view_list),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderProductScreen(
                            orderId: order.id,
                            orderStatus: order['status'] ?? 'Unknown',
                            userId: userId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

}

