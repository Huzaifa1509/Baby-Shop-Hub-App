import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class EditCategoryScreen extends StatefulWidget {
  final String categoryId;

  EditCategoryScreen({required this.categoryId});

  @override
  _EditCategoryScreenState createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final c_name = TextEditingController();
  PlatformFile? pickedfile;
  Uint8List? bytes;
  UploadTask? uploadTask;
  bool _isUploading = false;
  String? existingImageUrl;

  @override
  void initState() {
    super.initState();
    fetchCategoryDetails();
  }

  Future<void> fetchCategoryDetails() async {
    DocumentSnapshot categoryDoc = await FirebaseFirestore.instance.collection('CategoryCollection').doc(widget.categoryId).get();
    var category = categoryDoc.data() as Map<String, dynamic>;

    setState(() {
      c_name.text = category['name'];
      existingImageUrl = category['image'];
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
    c_name.clear();
    setState(() {
      pickedfile = null;
      bytes = null;
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
        title: Text('Edit Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16),
            TextField(
              controller: c_name,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
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
                if (c_name.text.isEmpty) {
                  _showSnackbar('Please fill all fields.');
                  return;
                }

                var imageUrl = await uploadFile();
                await updateCategory(c_name.text, imageUrl);
                _showSnackbar('Category updated successfully');
                Navigator.pop(context); // Go back to the previous screen after update
              },
              child: Text('Update Category'),
            ),
          
            if (_isUploading) buildProgress(), // Show progress bar only if uploading
          ],
        ),
      ),
    );
  }

  Future<void> updateCategory(String c_name, String? imageUrl) async {
    CollectionReference categories = FirebaseFirestore.instance.collection("CategoryCollection");

    try {
      await categories.doc(widget.categoryId).update({
        'name': c_name,
        'image': imageUrl,
      });
      print("Category Updated");
    } catch (error) {
      print("Failed to update category: $error");
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
}
