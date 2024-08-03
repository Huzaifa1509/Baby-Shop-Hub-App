import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class UploadCategoryScreen extends StatefulWidget {
  const UploadCategoryScreen({Key? key}) : super(key: key);

  @override
  _UploadCategoryScreenState createState() => _UploadCategoryScreenState();
}

class _UploadCategoryScreenState extends State<UploadCategoryScreen> {
  final categoryNameController = TextEditingController();
  PlatformFile? pickedfile;
  Uint8List? bytes;
  UploadTask? uploadTask;
  bool _isUploading = false; // Flag to control progress bar visibility

  @override
  void initState() {
    super.initState();
  }

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

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final platformFile = result.files.first;
    bytes = platformFile.bytes;
    setState(() {
      pickedfile = result.files.first;
    });
  }

  Future<int> getNextCategoryId() async {
    DocumentReference counterRef = FirebaseFirestore.instance.collection('Counters').doc('category_counter');
    DocumentSnapshot counterDoc = await counterRef.get();
    int nextId = 1;

    if (counterDoc.exists) {
      nextId = (counterDoc.data() as Map<String, dynamic>)['count'] + 1;
    }

    await counterRef.set({'count': nextId});
    return nextId;
  }

  void _clearForm() {
    categoryNameController.clear();
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
        title: Text('Upload Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16),
            TextField(
              controller: categoryNameController,
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
                if (categoryNameController.text.isEmpty || pickedfile == null) {
                  _showSnackbar('Please fill all fields and select an image.');
                  return;
                }

                var imageUrl = await uploadFile();
                int categoryId = await getNextCategoryId();
                await addCategory(categoryNameController.text, imageUrl, categoryId);
                _clearForm();
                _showSnackbar('Category added successfully');
              },
              child: Text('Add Category'),
            ),
            // Show progress bar only if uploading
            if (_isUploading) buildProgress(),
          ],
        ),
      ),
    );
  }

  Future<void> addCategory(String name, String? imageUrl, int categoryId) async {
    CollectionReference categories = FirebaseFirestore.instance.collection("CategoryCollection");

    try {
      await categories.doc('$categoryId').set({
        'name': name,
        'image': imageUrl,
      });
      print("Category Added");
    } catch (error) {
      print("Failed to add category: $error");
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
}
