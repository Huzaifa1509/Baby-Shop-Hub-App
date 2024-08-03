import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({Key? key}) : super(key: key);

  @override
  _UploadProductScreenState createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final p_name = TextEditingController();
  final p_desc = TextEditingController();
  final p_price = TextEditingController();
  String? category;
  Map<String, String> categories = {}; // Store category names and IDs

  bool _isUploading = false; // Flag to control progress bar visibility

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('CategoryCollection')
          .get();
      setState(() {
        categories = {
          for (var doc in snapshot.docs)
            doc.id: doc['name'] as String
        };
      });
    } catch (error) {
      print("Failed to fetch categories: $error");
    }
  }

  final CollectionReference Products2 =
      FirebaseFirestore.instance.collection('ProductCollection');

  PlatformFile? pickedfile;
  Uint8List? bytes;
  UploadTask? uploadTask;

  Future<String?> uploadFile() async {
    try {
      if (pickedfile == null || pickedfile!.bytes == null) {
        return null;
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

  Future SelectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final platformFile = result.files.first;
    bytes = platformFile.bytes;
    setState(() {
      pickedfile = result.files.first;
    });
  }

  Future<int> getNextProductId() async {
    DocumentReference counterRef = FirebaseFirestore.instance.collection('Counters').doc('product_counter');
    DocumentSnapshot counterDoc = await counterRef.get();
    int nextId = 1;

    if (counterDoc.exists) {
      nextId = (counterDoc.data() as Map<String, dynamic>)['count'] + 1;
    }

    await counterRef.set({'count': nextId});
    return nextId;
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
        title: Text('Upload Product'),
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
            else
              Text('No image selected'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                SelectFile();
              },
              child: Text("Select File"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (p_name.text.isEmpty ||
                    p_desc.text.isEmpty ||
                    p_price.text.isEmpty ||
                    category == null ||
                    pickedfile == null) {
                  _showSnackbar('Please fill all fields and select an image.');
                  return;
                }

                if (double.tryParse(p_price.text) == null) {
                  _showSnackbar('Price must be a number.');
                  return;
                }

                var imageUrl = await uploadFile();
                int productId = await getNextProductId();
                await addProduct(p_name.text, p_desc.text, p_price.text, category, imageUrl, productId);
                _clearForm();
                _showSnackbar('Product added successfully');
              },
              child: Text('Add Product'),
            ),
          
            if (_isUploading) buildProgress(), // Show progress bar only if uploading
          ],
        ),
      ),
    );
  }

  Future<void> addProduct(String p_name, String p_desc, String p_price, String? category, String? imageUrl, int productId) async {
    CollectionReference products = FirebaseFirestore.instance.collection("ProductCollection");
var prices = double.parse(p_price);
    try {
      await products.doc('$productId').set({
        'name': p_name,
        'desc': p_desc,
        'price': prices,
        'cat_id': category,
        'image': imageUrl,
      });
      print("Product Added");
    } catch (error) {
      print("Failed to add product: $error");
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
                      color: Color(0xFF508C9B),
                    ),
                    Center(
                      child: Text(
                        '${(100 * progress).roundToDouble()} %',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            } else {
              return SizedBox(height: 50);
            }
          })
      : SizedBox(height: 50);

  Widget _buildDropdownField(String label) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: category,
      onChanged: (String? newValue) {
        setState(() {
          category = newValue;
        });
      },
      items: categories.values.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: categories.entries.firstWhere((e) => e.value == value).key,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
