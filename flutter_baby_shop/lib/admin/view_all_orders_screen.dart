import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_products_screen.dart';

class ViewAllOrdersScreen extends StatelessWidget {
  final String userId;

  ViewAllOrdersScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('OrderCollection')
            .where('status', isEqualTo: 'pending') // Optional: filter orders by userId if needed
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching orders: ${snapshot.error}'));
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
                      // Text(order['status'] ?? 'Unknown'),
                      ElevatedButton(onPressed: (){
                        StatusChange(order.id);
                      },
                      child: Text('Fulfilled')),
                      IconButton(
                        icon: Icon(Icons.view_list),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderProductsScreen(
                                orderId: order.id,
                                orderStatus: order['status'] ?? 'Unknown',
                                 // Pass userId if needed in OrderProductsScreen
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
      ),
    );
  }

  void StatusChange(orderId) {
    FirebaseFirestore.instance
        .collection('OrderCollection')
        .doc(orderId)
        .update({'status': 'fulfilled'});
  }
}
