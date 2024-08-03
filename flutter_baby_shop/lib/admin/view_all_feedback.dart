import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatelessWidget {
  final String userId;

  FeedbackScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Feedbacks'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('FeedbackSupport')
            .orderBy('id', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching feedbacks: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No feedbacks found'));
          }

          var feedbacks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              var feedback = feedbacks[index];
              return Card(
                child: ListTile(
                  title: Row(children: [
                    Text(feedback['name'] ?? 'No Name', style: TextStyle(fontWeight: FontWeight.bold),),

                    VerticalDivider(),
                    Text(feedback['email'] ?? 'No Email'),
                    ]),
                  subtitle: Text('Message: ' + (feedback['message'] ?? '')),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Text(order['status'] ?? 'Unknown'),
                      
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}
