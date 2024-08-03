import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderProductScreen extends StatelessWidget {
  final String orderId;
  final String orderStatus;
  final String userId;

  OrderProductScreen({
    required this.orderId,
    required this.orderStatus,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Products'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('CheckoutCollection')
            .where('order_id', isEqualTo: orderId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching products: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No products found'));
          }

          var products = snapshot.data!.docs;

          

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              return Card(
                child: ListTile(
                  leading: product['image'] != null && product['image'].isNotEmpty
                      ? Image.network(product['image'], width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 50),
                  title: Text(product['name'] ?? 'No Product Name'),
                  subtitle: Text('Price: ' + (product['price']?.toString() ?? '0')),
                  trailing: orderStatus == 'fulfilled'
                      ? TextButton(
                          onPressed: () {
                            _checkExistingReview(context,product['product_id']);
                            print(product['product_id']);
                            print(userId);
                          },
                          child: Text('Review'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _checkExistingReview(BuildContext context, String productId) async {
    final reviewSnapshot = await FirebaseFirestore.instance
        .collection('ReviewsRatingsCollection')
        .where('product_id', isEqualTo: productId)
        .where('user_id', isEqualTo: userId)
        .get();

    if (reviewSnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already reviewed this product')),
      );
    } else {
      _showReviewDialog(context, productId);
    }
  }

  void _showReviewDialog(BuildContext context, String productId) {
    final TextEditingController _reviewController = TextEditingController();
    int _selectedStars = 0; // To store the selected star rating

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Write a Review'),
              backgroundColor: Colors.white, // Customize background color
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star rating section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedStars = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(labelText: 'Review'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedStars == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a star rating')),
                      );
                      return;
                    }
                    
                    try {
                      // Get the highest current ID
                      QuerySnapshot snapshot = await FirebaseFirestore.instance
                          .collection('ReviewsRatingsCollection')
                          .orderBy('id', descending: true)
                          .limit(1)
                          .get();
                      int newId = 1;
                      if (snapshot.docs.isNotEmpty) {
                        newId = snapshot.docs.first['id'] + 1;
                      }

                      // Save the review to Firestore
                      await FirebaseFirestore.instance.collection('ReviewsRatingsCollection').doc(newId.toString()).set({
                        'id': newId,
                        'product_id': productId,
                        'review': _reviewController.text,
                        'user_id': userId,
                        'stars': _selectedStars,
                      }).then((value) {
                        // Review submitted successfully
                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Review submitted successfully')),
                      );
                      });

                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit review: $e')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
