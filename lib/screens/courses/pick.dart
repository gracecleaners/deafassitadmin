import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageUploadWidget extends StatefulWidget {
  @override
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _image;

  // Function to pick image
  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      uploadImage(_image!);
    }
  }

  // Function to upload the image to Firebase Storage
  Future<void> uploadImage(File image) async {
    try {
      // Generate a unique name for the image
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child('courses/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);

      // Wait for upload to complete and get the download URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image uploaded! URL: $downloadUrl');
      // You can now store this URL in Firestore or use it as needed.
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Course Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!)
                : Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Pick an Image'),
            ),
          ],
        ),
      ),
    );
  }
}
