import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'intro.dart';
import 'login_screen.dart';
import 'home.dart';
import 'admin/admin_screen.dart';
 // Import Admin Drawer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDF4z7mPwIhpE_Qu1t7xiBH9c-zdCJb3gQ",
      appId: "1:61955691971:android:a400eb183ae61f56881976",
      messagingSenderId: "61955691971",
      projectId: "baby-shop-fad7d",
      storageBucket: "baby-shop-fad7d.appspot.com",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BabyShopHub',
      theme: ThemeData(
        primaryColor: Color(0xFF7AB2B2),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF4D869C), // accent color
        ),
        scaffoldBackgroundColor: Color(0xFFEEF7FF),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF000000)),
          bodyMedium: TextStyle(color: Color(0xFF000000)),
          headlineLarge: TextStyle(color: Color(0xFF000000)),
          headlineMedium: TextStyle(color: Color(0xFF000000)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF7AB2B2), // Background color
            foregroundColor: Colors.white, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      home: IntroScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }

  void onLogin(BuildContext context, String userId) async {
    String role = await getUserRole(userId);
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/adminDashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<String> getUserRole(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('UserCollection')
        .doc(userId)
        .get();
    return userDoc['role'];
  }
}

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(
        primaryColor: Color(0xFF201E43) ,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF134B70), // accent color
        ),
        scaffoldBackgroundColor: Color(0xFFEEEEEE),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF000000)),
          bodyMedium: TextStyle(color: Color(0xFF000000)),
          headlineLarge: TextStyle(color: Color(0xFF000000)),
          headlineMedium: TextStyle(color: Color(0xFF000000)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF508C9B), // Background color
            foregroundColor: Colors.white, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      initialRoute: '/adminDashboard',
      routes: {
        '/adminDashboard': (context) => AdminDashboardScreen(userId: 'userId'),
        
      },
    );
  }
}
