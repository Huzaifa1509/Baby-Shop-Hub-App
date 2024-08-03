import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class EditProductScreen extends StatefulWidget {
  final String productId;

  EditProductScreen({required this.productId});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final p_name = TextEditingController();
  final p_desc = TextEditingController();
  final p_price = TextEditingController();
  String? category;
  Map<String, String> categories = {};
  PlatformFile? pickedfile;
  Uint8List? bytes;
  UploadTask? uploadTask;
  bool _isUploading = false;
  String? existingImageUrl;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchProductDetails();
  }

  Future<void> fetchCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('CategoryCollection')
          .get();
      setState(() {
        categories = {
          for (var doc in snapshot.docs) doc.id: doc['name'] as String
        };
      });
    } catch (error) {
      print("Failed to fetch categories: $error");
    }
  }

  Future<void> fetchProductDetails() async {
    DocumentSnapshot productDoc = await FirebaseFirestore.instance
        .collection('ProductCollection')
        .doc(widget.productId)
        .get();
    var product = productDoc.data() as Map<String, dynamic>;

    setState(() {
      p_name.text = product['name'];
      p_desc.text = product['desc'];
      p_price.text = product['price'];
      category = product['cat_id'];
      existingImageUrl = product['image'];
    });
  }

  Future<String?> uploadFile() async {
    try {
      if (pickedfile == null || pickedfile!.bytes == null) {
        return existingImageUrl; // Return existing image URL if no new image is selected
      }
      final path = 'images/${pickedfile!.name}';
      final ref = FirebaseStorage.instance.ref().child(path);
      print(path);
      setState(() {
        _isUploading = true; // Show progress bar
        uploadTask = ref.putData(pickedfile!.bytes!);
      });

      final snapshot = await uploadTask!.whenComplete(() => {});
      final urlDownload = await snapshot.ref.getDownloadURL();
      print("URL Link $urlDownload");
      setState(() {
        uploadTask = null;
        _isUploading = false; // Hide progress bar after upload
      });
      return urlDownload;
    } on FirebaseException catch (ex) {
      print(ex.code.toString());
      return null;
    }
  }

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final platformFile = result.files.first;
    bytes = platformFile.bytes;
    setState(() {
      pickedfile = result.files.first;
    });
  }

  void _clearForm() {
    p_name.clear();
    p_desc.clear();
    p_price.clear();
    setState(() {
      pickedfile = null;
      bytes = null;
      category = null;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16),
            TextField(
              controller: p_name,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: p_desc,
              decoration: InputDecoration(
                labelText: 'Product Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: p_price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Product Price',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            SizedBox(height: 16),
            _buildDropdownField('Category'),
            SizedBox(height: 16),
            if (bytes != null)
              Container(
                height: 300,
                width: 300,
                child: Image.memory(bytes!, fit: BoxFit.cover),
              )
            else if (existingImageUrl != null)
              Container(
                height: 300,
                width: 300,
                child: Image.network(existingImageUrl!, fit: BoxFit.cover),
              )
            else
              Text('No image selected'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                selectFile();
              },
              child: Text("Select Image"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (p_name.text.isEmpty ||
                    p_desc.text.isEmpty ||
                    p_price.text.isEmpty ||
                    category == null) {
                  _showSnackbar('Please fill all fields.');
                  return;
                }

                if (double.tryParse(p_price.text) == null) {
                  _showSnackbar('Price must be a number.');
                  return;
                }

                var imageUrl = await uploadFile();
                await updateProduct(
                    p_name.text, p_desc.text, p_price.text, category, imageUrl);
                _showSnackbar('Product updated successfully');
                Navigator.pop(
                    context); // Go back to the previous screen after update
              },
              child: Text('Update Product'),
            ),

            if (_isUploading)
              buildProgress(), // Show progress bar only if uploading
          ],
        ),
      ),
    );
  }

  Future<void> updateProduct(String p_name, String p_desc, String p_price,
      String? category, String? imageUrl) async {
    CollectionReference products =
        FirebaseFirestore.instance.collection("ProductCollection");
    var prices = double.parse(p_price);
    try {
      await products.doc(widget.productId).update({
        'name': p_name,
        'desc': p_desc,
        'price': prices,
        'cat_id': category,
        'image': imageUrl,
      });
      print("Product Updated");
    } catch (error) {
      print("Failed to update product: $error");
    }
  }

  Widget buildProgress() => _isUploading
      ? StreamBuilder<TaskSnapshot>(
          stream: uploadTask?.snapshotEvents,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!;
              double progress = data.bytesTransferred / data.totalBytes;
              return SizedBox(
                height: 30,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey,
                      color: Colors.green,
                    ),
                    Center(
                      child: Text(
                        '${(100 * progress).roundToDouble()}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return const SizedBox(height: 30);
            }
          },
        )
      : Container();
  Widget _buildDropdownField(String labelText) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue),
      ),
      child: DropdownButtonFormField<String>(
        value: category,
        onChanged: (newValue) {
          setState(() {
            category = newValue;
          });
        },
        items: categories.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
