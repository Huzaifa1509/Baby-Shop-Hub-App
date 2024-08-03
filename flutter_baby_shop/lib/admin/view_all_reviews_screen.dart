import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllReviewsScreen extends StatelessWidget {
  final String userId;

  ViewAllReviewsScreen({required this.userId});

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    var userSnapshot = await FirebaseFirestore.instance.collection('UserCollection').doc(userId).get();
    return userSnapshot.data() as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _getProductData(String productId) async {
    var productSnapshot = await FirebaseFirestore.instance.collection('ProductCollection').doc(productId).get();
    return productSnapshot.data() as Map<String, dynamic>;
  }

  void _deleteReview(String reviewId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('ReviewsRatingsCollection').doc(reviewId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Reviews'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ReviewsRatingsCollection').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching reviews: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reviews found'));
          }

          var reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              var review = reviews[index].data() as Map<String, dynamic>;
              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserData(review['user_id']),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      title: Text('User not found'),
                    );
                  }

                  var user = userSnapshot.data!;
                  String userName = user['name'] ?? 'Anonymous';
                  String userImage = user['profile_pic'] ?? '';

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getProductData(review['product_id']),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: Text('Loading...'),
                        );
                      }
                      if (!productSnapshot.hasData) {
                        return ListTile(
                          title: Text('Product not found'),
                        );
                      }

                      var product = productSnapshot.data!;
                      String productName = product['name'] ?? 'Unknown Product';
                      String productImage = product['image'] ?? '';

                      return Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10.0),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < review['stars'] ? Icons.star : Icons.star_border,
                                    color: starIndex < review['stars'] ? Colors.yellow : Colors.grey,
                                  );
                                }),
                              ),
                              Text(userName),
                            ],
                          ),
                          subtitle: Text(review['review']),
                          leading: CircleAvatar(
                            backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                            child: userImage.isEmpty ? Icon(Icons.person) : null,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              productImage.isNotEmpty
                                  ? Image.network(productImage, width: 50, height: 50)
                                  : Placeholder(fallbackWidth: 50, fallbackHeight: 50),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteReview(reviews[index].id, context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
