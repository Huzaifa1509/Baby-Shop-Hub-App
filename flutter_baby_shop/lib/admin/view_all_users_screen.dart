import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllUsersScreen extends StatelessWidget {
  final String userId;

  ViewAllUsersScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('UserCollection')
        .where('role', isEqualTo: 'user')
        .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching users'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users found'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userDoc = snapshot.data!.docs[index];
              var userData = userDoc.data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userData['profile_pic'] ?? ''),
                ),
                title: Text(userData['name'] ?? 'No Username'),
                subtitle: Text(userData['email'] ?? 'No Email'),
              );
            },
          );
        },
      ),
    );
  }
}
