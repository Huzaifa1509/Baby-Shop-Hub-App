import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? userId;
  TextEditingController addressController = TextEditingController();
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    getUserId().then((_) {
      loadUserAddress();
      loadCartProducts();
    });
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  Future<void> loadUserAddress() async {
    if (userId == null) return;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('UserCollection')
        .doc(userId)
        .get();

    setState(() {
      addressController.text = userDoc['address'] ?? '';
    });
  }

  Future<void> loadCartProducts() async {
    if (userId == null) return;
    QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
        .collection('CartCollection')
        .where('user_id', isEqualTo: userId)
        .get();

    var cartItems = cartSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'product_id': data['product_id'],
        'name': data['product_name'],
        'price': data['product_price'],
        'quantity': data['product_qty'],
        'image_url': data['product_image'], // Assuming there's an image URL
      };
    }).toList();

    setState(() {
      products = cartItems;
    });
  }

  void updateQuantity(int index, int newQuantity) {
    setState(() {
      products[index]['quantity'] = newQuantity;
    });
  }

  // void removeProduct(int index) {
  //   setState(() {
  //     products.removeAt(index);
  //   });
  // }
  void removeProduct(int index, String name) async {
    print('Attempting to remove product with ID: $name'); // Debug print

    if (name == null || name.isEmpty) {
      print('Error: Product ID is null or empty');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('CartCollection')
          .where('product_name', isEqualTo: name)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete();
        }
      });

      setState(() {
        products.removeAt(index);
      });
    } catch (e) {
      print('Failed to remove product: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to remove product'),
      ));
    }
  }

  Future<int> getNextId(String collectionName) async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();
    return querySnapshot.size + 1;
  }

  Future<void> _placeOrder() async {
    // ScaffoldMessenger.of(context)
    //     .showSnackBar(SnackBar(content: Text('Placing order...')));
    if (userId == null) {
      Navigator.pushNamed(
          context, '/login'); // Redirect to login if not logged in
      return;
    }

    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Address is required')));
      return;
    }

    double totalAmount = products.fold(
      0,
      (sum, item) => sum + (item['price'] as num) * (item['quantity'] as num),
    );

    int orderId = await getNextId('OrderCollection');
    int checkoutId = await getNextId('CheckoutCollection');

    // Create the order document in OrderCollection
    await FirebaseFirestore.instance
        .collection('OrderCollection')
        .doc(orderId.toString())
        .set({
      'address': addressController.text,
      'order_time': Timestamp.now(),
      'status': 'pending',
      'total_amount': totalAmount,
      'user_id': userId,
    });

    // Add each product to the CheckoutCollection with the order ID as a foreign key
    for (var product in products) {
      await FirebaseFirestore.instance
          .collection('CheckoutCollection')
          .doc(checkoutId.toString())
          .set({
        'order_id': orderId.toString(),
        'product_id': product['product_id'],
        'name': product['name'],
        'price': product['price'],
        'image': product['image_url'],
        'quantity': product['quantity'],
      });
      checkoutId++;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Order placed successfully')));

    // Optionally, clear the cart
    clearCart();
    Navigator.pop(context); // Go back to the previous screen
  }

  Future<void> clearCart() async {
    QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
        .collection('CartCollection')
        .where('user_id', isEqualTo: userId)
        .get();
    for (var doc in cartSnapshot.docs) {
      doc.reference.delete();
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your address',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var product = products[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image.network(
                            product['image_url'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name']),
                              Text('Rs.'+'${product['price']}'),
                            ],
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              if (product['quantity'] > 1) {
                                updateQuantity(index, product['quantity'] - 1);
                              }
                            },
                          ),
                          Text('${product['quantity']}'),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              updateQuantity(index, product['quantity'] + 1);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              removeProduct(index, product['name']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              'Total Amount: '+'Rs.'+'${products.fold<double>(0.0, (double sum, item) => sum + (item['price'] as num) * (item['quantity'] as num))}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _placeOrder,
                child: Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
