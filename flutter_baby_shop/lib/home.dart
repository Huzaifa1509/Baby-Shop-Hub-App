import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/models/product_model.dart';
import 'category_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'all_products_screen.dart';
import 'login_screen.dart';
import 'feedback.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userId;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baby Shop Hub'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              showCart(context);
            },
          ),
          IconButton(
            icon: userId != null
                ? FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('UserCollection')
                        .doc(userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          var userDoc = snapshot.data!;
                          var imageUrl = userDoc['profile_pic'];
                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            return CircleAvatar(
                              backgroundImage: NetworkImage(imageUrl),
                            );
                          } else {
                            return Icon(Icons.person);
                          }
                        } else {
                          return Icon(Icons.person);
                        }
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  )
                : Icon(Icons.person),
            onPressed: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: userId!)),
                );
              } else {
                Navigator.pushNamed(context, '/login'); // Redirect to login
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 250,
              color: Color(0xFFCDE8E5),
              child: Image.asset(
                'assets/images/banner1.png',
                width: 450,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(10),
            sliver: SliverToBoxAdapter(
              child: CategoryTilesSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Best Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          BestProductsSection(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AllProductsScreen()));
          }, child: Text('View All')),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              height: 250,
              color: Color(0xFFCDE8E5),
              child: Image.asset(
                'assets/images/banner3.png',
                width: 450,
                height: 350,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              color: Color(0xFF4D869C),
              child: Center(
                  child: Text(
                      'CopyRight All Rights Reserved by Flutter Baby Shop',
                      style: TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: Icon(Icons.arrow_upward),
        backgroundColor: Color(0xFF4D869C),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
DrawerHeader(
  child: userId != null
      ? FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('UserCollection')
              .doc(userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData && snapshot.data!.exists) {
                var userDoc = snapshot.data!;
                var imageUrl = userDoc['profile_pic'];
                var username = userDoc['name'] ?? 'Guest';
                return Container(
                  color: Colors.transparent, // Remove default background color
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : AssetImage('assets/default_user.png') as ImageProvider,
                        radius: 30,
                      ),
                      SizedBox(width: 16), // Spacing between image and text
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  color: Colors.transparent, // Remove default background color
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 30,
                      ),
                      SizedBox(width: 16), // Spacing between image and text
                      Text(
                        'Guest',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
            } else {
              return Container(
                color: Colors.transparent, // Remove default background color
                child: Row(
                  children: [
                    CircleAvatar(
                      child: CircularProgressIndicator(),
                      radius: 30,
                    ),
                    SizedBox(width: 16), // Spacing between image and text
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        )
      : Container(
          color: Colors.transparent, // Remove default background color
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(Icons.person),
                radius: 30,
              ),
              SizedBox(width: 16), // Spacing between image and text
              Text(
                'Guest',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Cart'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedback & Support'),
              onTap: () {
                Navigator.push(context,MaterialPageRoute(builder: (context) => FeedbackFormScreen(userId: userId!,)) );
              },
            ),
            if (userId != null)
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.remove('userId');
                  setState(() {
                    userId = null;
                  });
                  Navigator.pushReplacementNamed(context, '/login');
                },
              )
            else
              ListTile(
                leading: Icon(Icons.login),
                title: Text('Login Now'),
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
          ],
        ),
      ),
    );
  }

void showCart(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('CartCollection')
              .where('user_id', isEqualTo: userId)
              .get(),
          builder: (context, snapshot) {
                if(userId == null){
      return Center(child: Text('The Cart is Empty!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),) );
    }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('The Cart is Empty!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),));
            }
            var cartItems = snapshot.data!.docs;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Cart Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    return ListTile(
                      leading: Image.network(item['product_image']),
                      title: Text(item['product_name']),
                      subtitle: Text('Rs.'+'${item['product_price']}'),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CheckoutScreen()),
                    );
                  },
                  child: Text('View Cart'),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

}

class CategoryTilesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('CategoryCollection')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return Center(child: Text('No categories available'));
        }

        final categories = snapshot.data!.docs;

        return GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CategoryScreen(categoryId: category.id, categoryName: category['name'])),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        child: Image.network(
                          category['image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          category['name'],
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class BestProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ProductCollection')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(child: Text('No products available')),
          );
        }

        final products = snapshot.data!.docs.map((doc) {
          return Product.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return SliverPadding(
          padding: EdgeInsets.all(10),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ProductScreen(productId: product.id)),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: Image.network(
                            product.image,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Rs'+'.${product.price}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}
