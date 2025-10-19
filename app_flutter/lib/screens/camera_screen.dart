import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String? _pickedVideoPath;
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _communityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _pickedVideoPath = video.path;
      });
      // Show dialog to enter description, hashtag, and community
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Tag your video'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _hashtagController,
                    decoration: InputDecoration(
                      labelText: 'Hashtag (challenge)',
                      prefixText: '#',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _communityController,
                    decoration: InputDecoration(
                      labelText: 'Community',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              ElevatedButton(
                child: Text('Upload'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        },
      );
      // Save into global state for Profile/Home
      try {
        final provider = context.read<VideoProvider>();
        provider.addLocalVideo(
          video.path,
          description: _descriptionController.text.trim(),
          hashtag: _hashtagController.text.trim(),
          community: _communityController.text.trim(),
        );
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picked video: ${video.name}')),
      );
      _descriptionController.clear();
      _hashtagController.clear();
      _communityController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Camera')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  'Camera UI placeholder. Recording and tagging flow to be implemented.'),
              SizedBox(height: 24),
              ElevatedButton(
                child: Text('Pick Video from Gallery'),
                onPressed: _pickVideo,
              ),
              if (_pickedVideoPath != null) ...[
                SizedBox(height: 16),
                Text('Selected video path:'),
                Text(_pickedVideoPath!,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
