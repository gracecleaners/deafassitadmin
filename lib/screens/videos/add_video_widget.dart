import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class AddVideoWidget extends StatefulWidget {
  const AddVideoWidget({Key? key}) : super(key: key);

  @override
  _AddVideoWidgetState createState() => _AddVideoWidgetState();
}

class _AddVideoWidgetState extends State<AddVideoWidget> {
  File? _thumbnail;
  String? _thumbnailPath;
  String? _videoLink;
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final videoSnapshot = await FirebaseFirestore.instance.collection('videos').get();
    setState(() {
      _videos = videoSnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _openVideoUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('videos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final videos = snapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _openVideoUrl(video['videoUrl']),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16/9,
                              child: video['thumbnailUrl'] != null
                                  ? Image.network(
                                      video['thumbnailUrl']!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Icon(Icons.error),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.video_library),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    video['description'] ?? '',
                                    style: TextStyle(fontSize: 14),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Rest of the code remains the same...
  Future<void> _pickThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _thumbnailPath = result.files.first.path;
          _thumbnail = File(_thumbnailPath!);
        });
      }
    } catch (e) {
      print('Error picking thumbnail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting thumbnail: $e')),
      );
    }
  }

  void _showAddVideoDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final instructorController = TextEditingController();
    final modeController = TextEditingController();
    final videoLinkController = TextEditingController();

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
                    decoration: InputDecoration(labelText: 'Mode (Online/Offline)'),
                  ),
                  TextFormField(
                    controller: videoLinkController,
                    decoration: InputDecoration(labelText: 'Video Link'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a video link';
                      }
                      if (!Uri.parse(value).isAbsolute) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _thumbnailPath == null
                                ? 'No thumbnail selected'
                                : 'Thumbnail selected!',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String? thumbnailUrl;
                  if (_thumbnail != null) {
                    try {
                      thumbnailUrl = await uploadFile(_thumbnail!, 'thumbnails');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to upload thumbnail: $e')),
                      );
                      return;
                    }
                  }

                  Map<String, dynamic> newVideo = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'instructor': instructorController.text,
                    'mode': modeController.text,
                    'videoUrl': videoLinkController.text,
                    'thumbnailUrl': thumbnailUrl,
                    'timestamp': DateTime.now(),
                  };

                  try {
                    await addVideo(context, newVideo);
                    Navigator.pop(context);
                    _loadVideos(); // Refresh the video list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add video: $e')),
                    );
                  }
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
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
      Reference ref = storage.ref().child(fileName);
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      print("$folder uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading $folder: $e");
      throw Exception('Failed to upload $folder: $e');
    }
  }

  Future<void> addVideo(BuildContext context, Map<String, dynamic> video) async {
    try {
      await FirebaseFirestore.instance.collection('videos').add(video);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video added successfully!')),
      );
    } catch (e) {
      print('Error adding video: $e');
      throw Exception('Failed to add video: $e');
    }
  }
}