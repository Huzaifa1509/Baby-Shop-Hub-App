import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_category.dart';

class ViewAllCategoriesScreen extends StatelessWidget {
  final String userId;

  ViewAllCategoriesScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Categories'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('CategoryCollection').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              var category = categories[index];
              var categoryId = category.id;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: ListTile(
                  leading: category['image'] != null
                      ? Image.network(category['image'], width: 50, height: 50, fit: BoxFit.cover)
                      : Placeholder(fallbackWidth: 50, fallbackHeight: 50),
                  title: Text(category['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCategoryScreen(categoryId: categoryId),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('CategoryCollection').doc(categoryId).delete();
                        },
                      ),
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
