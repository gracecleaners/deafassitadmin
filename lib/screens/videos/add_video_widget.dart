import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddVideoWidget extends StatefulWidget {
  const AddVideoWidget({Key? key}) : super(key: key);

  @override
  _AddVideoWidgetState createState() => _AddVideoWidgetState();
}

class _AddVideoWidgetState extends State<AddVideoWidget> {
  File? _thumbnail;
  String? _thumbnailPath;
  File? _videoFile;
  String? _videoPath;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Videos",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddVideoDialog(context),
                icon: Icon(Icons.add),
                label: Text("Add Video"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickThumbnail() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _thumbnailPath = result.files.single.path;
        _thumbnail = File(_thumbnailPath!);
      });
    }
  }

  Future<void> _pickVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        _videoPath = result.files.single.path;
        _videoFile = File(_videoPath!);
      });
    }
  }

  void _showAddVideoDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final instructorController = TextEditingController();
    final modeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Video'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Video Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a video title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: instructorController,
                    decoration: InputDecoration(labelText: 'Instructor'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an instructor name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: modeController,
                    decoration:
                        InputDecoration(labelText: 'Mode (Online/Offline)'),
                  ),
                  // Video Picker Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_videoPath == null
                            ? 'No video selected'
                            : 'Video selected!'),
                        IconButton(
                          icon: Icon(Icons.video_library),
                          onPressed: _pickVideoFile,
                        ),
                      ],
                    ),
                  ),
                  // Thumbnail Picker Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_thumbnailPath == null
                            ? 'No thumbnail selected'
                            : 'Thumbnail selected!'),
                        IconButton(
                          icon: Icon(Icons.photo),
                          onPressed: _pickThumbnail,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Upload files to Firebase Storage
                  String? videoUrl;
                  String? thumbnailUrl;

                  if (_videoFile != null) {
                    videoUrl = await uploadFile(_videoFile!, 'videos');
                  }

                  if (_thumbnail != null) {
                    thumbnailUrl = await uploadFile(_thumbnail!, 'thumbnails');
                  }

                  // Create the video object with all the form values
                  Map<String, dynamic> newVideo = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'instructor': instructorController.text,
                    'mode': modeController.text,
                    'videoUrl': videoUrl,
                    'thumbnailUrl': thumbnailUrl,
                  };

                  // Add the video to Firestore
                  addVideo(context, newVideo);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> uploadFile(File file, String folder) async {
    try {
      // Create a reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName =
          '$folder/${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
      Reference ref = storage.ref().child(fileName);

      // Upload the file
      await ref.putFile(file);

      // Get the download URL
      String downloadUrl = await ref.getDownloadURL();
      print("$folder uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading $folder: $e");
      throw Exception('Failed to upload $folder: $e');
    }
  }

  void addVideo(BuildContext context, Map<String, dynamic> video) async {
    try {
      // Add video to Firestore
      await FirebaseFirestore.instance.collection('videos').add(video);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Video added successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add video: $e')));
    }
  }
}
