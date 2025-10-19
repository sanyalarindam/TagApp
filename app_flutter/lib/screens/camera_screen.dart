import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String? _pickedVideoPath;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _pickedVideoPath = video.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picked video: ${video.name}')),
      );
      // TODO: Upload logic here
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
