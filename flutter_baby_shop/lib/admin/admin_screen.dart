import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shop/admin/view_all_feedback.dart';
import 'view_all_orders_screen.dart';
import 'view_all_users_screen.dart';
import 'view_all_products_screen.dart';
import 'view_all_categories_screen.dart';
import 'view_all_reviews_screen.dart';
import 'admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String userId;

  AdminDashboardScreen({required this.userId});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _userName;
  int _totalOrders = 0;
  int _totalUsers = 0;
  int _totalProducts = 0;
  int _totalCategories = 0;
  int _totalReviews = 0;
  int _totalFeedbacks = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchCollectionCounts();
  }

  Future<void> _fetchUserData() async {
    var userSnapshot = await FirebaseFirestore.instance.collection('UserCollection').doc(widget.userId).get();
    setState(() {
      _userName = userSnapshot.data()?['name'] ?? 'User';
    });
  }

  Future<void> _fetchCollectionCounts() async {
    var ordersSnapshot = await FirebaseFirestore.instance.collection('OrderCollection').where('status', isEqualTo: 'pending').get();
    var usersSnapshot = await FirebaseFirestore.instance.collection('UserCollection').where('role', isEqualTo: 'user').get();
    var productsSnapshot = await FirebaseFirestore.instance.collection('ProductCollection').get();
    var categoriesSnapshot = await FirebaseFirestore.instance.collection('CategoryCollection').get();
    var reviewsSnapshot = await FirebaseFirestore.instance.collection('ReviewsRatingsCollection').orderBy('id', descending: true).get();
    var feedbacksSnapshot = await FirebaseFirestore.instance.collection('FeedbackSupport').orderBy('id', descending: true).get();

    setState(() {
      _totalOrders = ordersSnapshot.size;
      _totalUsers = usersSnapshot.size;
      _totalProducts = productsSnapshot.size;
      _totalCategories = categoriesSnapshot.size;
      _totalReviews = reviewsSnapshot.size;
      _totalFeedbacks = feedbacksSnapshot.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Welcome, $_userName',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(context, 'Total Orders: $_totalOrders', Icons.shopping_cart, ViewAllOrdersScreen(userId: widget.userId)),
                  _buildDashboardCard(context, 'Total Users: $_totalUsers', Icons.people, ViewAllUsersScreen(userId: widget.userId)),
                  _buildDashboardCard(context, 'Total Products: $_totalProducts', Icons.category, ViewAllProductsScreen(userId: widget.userId)),
                  _buildDashboardCard(context, 'Total Categories: $_totalCategories', Icons.list, ViewAllCategoriesScreen(userId: widget.userId)),
                  // _buildDashboardCard(context, 'Fetch Latest Orders', Icons.refresh, ViewAllOrdersScreen(userId: widget.userId)),
                  _buildDashboardCard(context, 'Latest Reviews: $_totalReviews', Icons.sentiment_very_satisfied_rounded, ViewAllReviewsScreen(userId: widget.userId)),
                  _buildDashboardCard(context, 'Latest Feedbacks: $_totalFeedbacks', Icons.feedback, FeedbackScreen(userId: widget.userId)),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: AdminDrawer(userId: widget.userId),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Widget screen) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Card(
        color: Color(0xFF201E43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
