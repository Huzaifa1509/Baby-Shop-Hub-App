import 'dart:html' as html; // Import for web
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  String imageUrl = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                height: 200,
                child: Image.asset('assets/images/logo.png'), // Add your logo asset here
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Delivery Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your delivery address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await uploadProfilePicture();
                },
                child: Text('Upload Profile Picture'),
              ),
              SizedBox(height: 20),
              imageUrl.isNotEmpty
                  ? Image.network(imageUrl, height: 150, width: 150)
                  : Text('No image selected'),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (imageUrl.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please upload a profile picture'),
                              ),
                            );
                            return;
                          }
                          _registerUser(
                            nameController.text,
                            emailController.text,
                            passwordController.text,
                            addressController.text,
                          );
                        }
                      },
                      child: Text('Register'),
                    ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an Account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> uploadProfilePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Select image from file picker
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoadEnd.listen((e) async {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pics/${DateTime.now().toString()}');
          final uploadTask = storageRef.putBlob(files[0]);

          try {
            await uploadTask;
            imageUrl = await storageRef.getDownloadURL();
            setState(() {
              imageUrl = imageUrl;
            });
          } catch (error) {
            print('Failed to upload image: $error');
          }
        });
      });
    } catch (error) {
      print('Error selecting image: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerUser(
    String name,
    String email,
    String password,
    String address,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email already exists
      QuerySnapshot emailSnapshot = await FirebaseFirestore.instance
          .collection('UserCollection')
          .where('email', isEqualTo: email)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email already exists')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the next user ID
      DocumentSnapshot counterDoc = await FirebaseFirestore.instance
          .collection('Counters')
          .doc('user_count')
          .get();

      int nextId = 1;
      if (counterDoc.exists) {
        final counterData = counterDoc.data() as Map<String, dynamic>;
        nextId = counterData['count'] ?? 1;
      } else {
        await FirebaseFirestore.instance
            .collection('Counters')
            .doc('user_count')
            .set({'count': nextId});
      }

      // Increment user ID
      await FirebaseFirestore.instance
          .collection('Counters')
          .doc('user_count')
          .update({'count': nextId + 1});

      await FirebaseFirestore.instance.collection('UserCollection').doc(nextId.toString()).set({
        'name': name,
        'email': email,
        'password': password,
        'delivery_address': address,
        'profile_pic': imageUrl,
        'role': 'user',
        'created_at': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign up: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
