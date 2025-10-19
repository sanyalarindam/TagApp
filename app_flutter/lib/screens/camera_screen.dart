import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../services/backend_api.dart';

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
      // Upload to backend (presign -> S3 upload -> create post)
      try {
        final api = BackendApi.instance;
        final presign = await api.getPresignedUrl(contentType: 'video/mp4');
        await api.uploadToPresignedUrl(
          uploadUrl: presign['uploadUrl']!,
          file: File(video.path),
          contentType: 'video/mp4',
        );
        // Store the S3 key, backend will generate presigned URLs when fetching
        final objectKey = presign['objectKey']!;
        await api.createPost(
          userId: api.currentUserId,
          username: api.currentUsername,
          videoUrl: objectKey, // Just the S3 key
          description: _descriptionController.text.trim(),
          hashtags: _hashtagController.text.isEmpty
              ? []
              : [_hashtagController.text.trim()],
          taggedFriends: const [],
          taggedCommunities: _communityController.text.isEmpty
              ? []
              : [_communityController.text.trim()],
        );

        // Optimistically add to local UI feed with full URL for immediate playback
        final provider = context.read<VideoProvider>();
        provider.addLocalVideo(
          video.path, // Keep local path for immediate playback
          description: _descriptionController.text.trim(),
          hashtag: _hashtagController.text.trim(),
          community: _communityController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${video.name}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }

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
