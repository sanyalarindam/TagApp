import 'package:flutter/material.dart';

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
    });
    await Future.delayed(const Duration(seconds: 2)); // Simulate network call
    // TODO: Replace with actual AI confirmation logic
    setState(() {
      _aiResult = 'AI confirms video matches challenge description!';
      _isSubmitting = false;
    });
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
                  : const Text('Submit'),
              onPressed: (_videoPath != null && !_isSubmitting)
                  ? _submitChallenge
                  : null,
            ),
            if (_aiResult != null) ...[
              const SizedBox(height: 24),
              Text(_aiResult!,
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}
