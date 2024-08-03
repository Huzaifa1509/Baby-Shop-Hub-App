import 'package:flutter/material.dart';
import 'view_all_users_screen.dart';
import 'view_all_orders_screen.dart';
import 'view_all_reviews_screen.dart';
import 'view_all_products_screen.dart';
import 'view_all_categories_screen.dart';
import 'upload_category_screen.dart';
import 'upload_product_screen.dart';
import 'admin_profile.dart';
import 'view_all_feedback.dart';
import '../login_screen.dart';

class AdminDrawer extends StatelessWidget {
  final String userId;

  AdminDrawer({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF201E43),
            ),
            child: Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('My Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminProfileScreen(userId: userId)),
              );
              // Implement admin profile route
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.category),
            title: Text('Manage Products'),
            children: <Widget>[
              ListTile(
                title: Text('Add Product'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UploadProductScreen()),
                  );
                },
              ),
              ListTile(
                title: Text('View Products'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ViewAllProductsScreen(userId: userId,)),
                  );
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.list),
            title: Text('Manage Categories'),
            children: <Widget>[
              ListTile(
                title: Text('Add Category'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UploadCategoryScreen()),
                  );
                },
              ),
              ListTile(
                title: Text('View Categories'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ViewAllCategoriesScreen(userId: userId,)),
                  );
                },
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.star),
            title: Text('View Reviews'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewAllReviewsScreen(userId: userId,)),
              );
            },
          ),
                    ListTile(
            leading: Icon(Icons.feedback),
            title: Text('View Feedbacks'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeedbackScreen(userId: userId,)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('View Orders'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewAllOrdersScreen(userId: userId,)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('View Users'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewAllUsersScreen(userId: userId,)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              // Handle logout
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
