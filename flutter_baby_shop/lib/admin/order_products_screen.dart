import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProductsScreen extends StatelessWidget {
  final String orderId;
  final String orderStatus;


  OrderProductsScreen({
    required this.orderId,
    required this.orderStatus,
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
