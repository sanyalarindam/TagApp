import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  const VideoPlayerScreen({Key? key, required this.videoPath})
      : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initializing = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initializing = false);
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _error = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Player')),
      body: Center(
        child: _initializing
            ? const CircularProgressIndicator()
            : _error
                ? const Text('Failed to load video',
                    style: TextStyle(color: Colors.white))
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        Positioned(
                          bottom: 24,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: [
                              IconButton(
                                color: Colors.white,
                                icon: Icon(_controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                                onPressed: () {
                                  setState(() {
                                    _controller.value.isPlaying
                                        ? _controller.pause()
                                        : _controller.play();
                                  });
                                },
                              ),
                              Expanded(
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  colors: VideoProgressColors(
                                      playedColor: Colors.blueAccent),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
      ),
    );
  }
}
