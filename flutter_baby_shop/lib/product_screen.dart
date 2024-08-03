import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductScreen extends StatefulWidget {
  final String productId;

  ProductScreen({required this.productId});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<DocumentSnapshot> _productFuture;
  String? userId;

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance.collection('ProductCollection').doc(widget.productId).get();
    getUserId();
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('UserCollection').doc(userId).get();
    return userSnapshot.data() as Map<String, dynamic>;
  }

  void _addToCart() async {
    if (userId == null) {
      Navigator.pushNamed(context, '/login'); // Redirect to login if not logged in
    } else {
      var productSnapshot = await FirebaseFirestore.instance.collection('ProductCollection').doc(widget.productId).get();
      var product = productSnapshot.data() as Map<String, dynamic>;

      // Check if the product is already in the cart
      var cartQuery = FirebaseFirestore.instance
          .collection('CartCollection')
          .where('user_id', isEqualTo: userId)
          .where('product_name', isEqualTo: product['name'])
          .limit(1)
          .get();

      if ((await cartQuery).docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product already added, increase the quantity in cart')));
      } else {
        CollectionReference usercart = FirebaseFirestore.instance.collection('CartCollection');
        QuerySnapshot querySnapshot = await usercart.get();
        int newId = querySnapshot.size + 1;

        usercart.doc(newId.toString()).set({
          'product_id': widget.productId,
          'product_desc': product['desc'],
          'product_image': product['image'],
          'product_name': product['name'],
          'product_price': product['price'],
          'product_qty': 1, // Default quantity to 1
          'user_id': userId,
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product added to cart')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Product not found'));
          }

          var product = snapshot.data!.data() as Map<String, dynamic>;

          // Safely retrieve and check for null values
          String image = product['image'] ?? '';
          String name = product['name'] ?? 'No Name';
          String description = product['desc'] ?? 'No Description';
          String price = product['price']?.toString() ?? '0';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                image.isNotEmpty
                    ? Image.network(image)
                    : Placeholder(), // Use a placeholder if image URL is empty
                SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Rs.'+'${price}',
                  style: TextStyle(fontSize: 20, color: Colors.green),
                ),
                SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addToCart,
                  child: Text('Add to Cart'),
                ),
                SizedBox(height: 16),
                Text(
                  'Rating & Reviews',
                  style: TextStyle(fontSize: 20),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ReviewsRatingsCollection')
                      .where('product_id', isEqualTo: widget.productId)
                      // .orderBy('id', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No reviews found'));
                    }

                    var reviews = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
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

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                                child: userImage.isEmpty ? Icon(Icons.person) : null,
                              ),
                              title: Text(userName),
                              subtitle: Text(review['review']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < review['stars'] ? Icons.star : Icons.star_border,
                                    color: starIndex < review['stars'] ? Colors.yellow : Colors.grey,
                                  );
                                }),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
