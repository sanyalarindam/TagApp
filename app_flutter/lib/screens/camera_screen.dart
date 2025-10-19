import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../services/backend_api.dart';

class CameraScreen extends StatefulWidget {
  final String? prefillHashtag;
  final String? prefillCommunity;
  final String? responseToPostId;
  final String? responseToUsername;
  const CameraScreen(
      {Key? key,
      this.prefillHashtag,
      this.prefillCommunity,
      this.responseToPostId,
      this.responseToUsername})
      : super(key: key);
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String? _pickedVideoPath;
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _communityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _taggedUsersController = TextEditingController();

  String? _uploadMsg;
  @override
  void initState() {
    super.initState();
    // Apply prefill if provided
    if (widget.prefillHashtag != null && widget.prefillHashtag!.isNotEmpty) {
      _hashtagController.text = widget.prefillHashtag!;
    }
    if (widget.prefillCommunity != null &&
        widget.prefillCommunity!.isNotEmpty) {
      _communityController.text = widget.prefillCommunity!;
    }
    // If it is a response, add a friendly default description prefix
    if (widget.responseToUsername != null &&
        widget.responseToUsername!.isNotEmpty) {
      _descriptionController.text = 'Response to @${widget.responseToUsername}';
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _pickedVideoPath = video.path;
        _uploadMsg = null;
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
                    controller: _taggedUsersController,
                    decoration: InputDecoration(
                        labelText: 'Tag users (comma-separated usernames)'),
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
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  // Upload to backend (presign -> S3 upload -> create post)
                  try {
                    final api = BackendApi.instance;
                    final presign =
                        await api.getPresignedUrl(contentType: 'video/mp4');
                    await api.uploadToPresignedUrl(
                      uploadUrl: presign['uploadUrl']!,
                      file: File(video.path),
                      contentType: 'video/mp4',
                    );
                    final objectKey = presign['objectKey']!;
                    final taggedUsernames = _taggedUsersController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    // Run AI verification; if unavailable or unauthorized, warn but proceed
                    try {
                      setState(() {
                        _uploadMsg = 'Verifying video...';
                      });
                      final verify = await api.verifyVideo(
                        objectKey: objectKey,
                        description: _descriptionController.text.trim(),
                      );
                      final bool verified = (verify['verified'] == true);
                      if (!verified) {
                        final String msg = (verify['message'] ??
                                'Video does not match the description')
                            .toString();
                        // Soft-fail: allow post, but show a warning
                        _uploadMsg =
                            '⚠️ Verification warning: ' + msg + ' (Proceeding)';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(_uploadMsg!),
                              backgroundColor: Colors.orange),
                        );
                      }
                    } catch (e) {
                      // Soft-fail on infrastructure errors (e.g., Unauthorized): proceed with upload
                      _uploadMsg = '⚠️ Verification unavailable: ' +
                          e.toString() +
                          ' (Proceeding)';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(_uploadMsg!),
                            backgroundColor: Colors.orange),
                      );
                    }
                    await api.createPost(
                      userId: api.currentUserId,
                      username: api.currentUsername,
                      videoUrl: objectKey,
                      description: _descriptionController.text.trim(),
                      hashtags: _hashtagController.text.isEmpty
                          ? []
                          : [_hashtagController.text.trim()],
                      taggedFriends: const [],
                      taggedUsernames: taggedUsernames,
                      taggedCommunities: _communityController.text.isEmpty
                          ? []
                          : [_communityController.text.trim()],
                      responseToPostId: widget.responseToPostId,
                    );
                    setState(() {
                      _uploadMsg = '✅ Uploaded successfully';
                    });
                    final provider = context.read<VideoProvider>();
                    provider.addLocalVideo(
                      video.path,
                      description: _descriptionController.text.trim(),
                      hashtag: _hashtagController.text.trim(),
                      community: _communityController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(_uploadMsg!),
                          backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    String msg = e.toString();
                    setState(() {
                      _uploadMsg = '❌ Upload failed: $msg';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(_uploadMsg!),
                          backgroundColor: Colors.red),
                    );
                  }
                  _descriptionController.clear();
                  _hashtagController.clear();
                  _communityController.clear();
                  _taggedUsersController.clear();
                },
              ),
            ],
          );
        },
      );
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
                if (_uploadMsg != null) ...[
                  SizedBox(height: 12),
                  Text(_uploadMsg!,
                      style: TextStyle(
                        color: _uploadMsg!.startsWith('✅')
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      )),
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}
