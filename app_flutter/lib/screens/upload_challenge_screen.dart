import 'package:flutter/material.dart';
import '../services/backend_api.dart';

class UploadChallengeScreen extends StatefulWidget {
  final String challengeDescription;
  const UploadChallengeScreen({Key? key, required this.challengeDescription})
      : super(key: key);

  @override
  State<UploadChallengeScreen> createState() => _UploadChallengeScreenState();
}

class _UploadChallengeScreenState extends State<UploadChallengeScreen> {
  String? _videoPath;
  bool _isSubmitting = false;
  String? _aiResult;
  bool _isVerified = false;

  // Placeholder for video picker/recorder
  Future<void> _pickVideo() async {
    // TODO: Integrate with camera/video picker
    setState(() {
      _videoPath = 'sample_video.mp4'; // Placeholder
    });
  }

  // Placeholder for AWS Bedrock/TwelveLabs AI confirmation
  Future<void> _submitChallenge() async {
    setState(() {
      _isSubmitting = true;
      _aiResult = null;
      _isVerified = false;
    });
    try {
      final api = BackendApi.instance;
      await api.createPost(
        userId: api.currentUserId,
        username: api.currentUsername,
        videoUrl: _videoPath ?? '',
        description: widget.challengeDescription,
        hashtags: const [],
        taggedFriends: const [],
        taggedUsernames: const [],
        taggedCommunities: const [],
      );
      setState(() {
        _aiResult = '✅ Verified: Your video matches the challenge!';
        _isVerified = true;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Verified: Your video matches the challenge!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      final msg = e.toString();
      setState(() {
        _isVerified = false;
        if (msg.contains('400') && msg.contains('Video does not match')) {
          _aiResult =
              '❌ Not Verified: Your video does not match the challenge.';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Not Verified: Your video does not match the challenge.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          _aiResult = '❌ Upload failed: $msg';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Upload failed: $msg'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Challenge Proof')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Challenge:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.challengeDescription),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: Text(
                  _videoPath == null ? 'Pick/Record Video' : 'Change Video'),
              onPressed: _isSubmitting ? null : _pickVideo,
            ),
            if (_videoPath != null) ...[
              const SizedBox(height: 16),
              Text('Selected video: $_videoPath'),
            ],
            const Spacer(),
            ElevatedButton(
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : (_isVerified
                      ? const Text('Verified!')
                      : const Text('Submit')),
              onPressed: (_videoPath != null && !_isSubmitting && !_isVerified)
                  ? _submitChallenge
                  : null,
            ),
            if (_aiResult != null) ...[
              const SizedBox(height: 24),
              Text(
                _aiResult!,
                style: TextStyle(
                  color: _aiResult!.startsWith('✅') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
