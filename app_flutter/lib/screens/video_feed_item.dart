import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import './_description_fade_text.dart';

class VideoFeedItem extends StatefulWidget {
  final VideoItem videoItem;
  const VideoFeedItem({Key? key, required this.videoItem}) : super(key: key);

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoItem.path))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isInitialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player (full width, centered vertically) with tap-to-pause
          Center(
            child: _isInitialized
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  )
                : Container(color: Colors.black),
          ),
          // Side action buttons (right side, vertically centered)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User avatar with follow button overlay
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Navigate to user profile')),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[300],
                          child:
                              const Icon(Icons.person, color: Colors.black54),
                        ),
                        // Plus button overlay (bottom right of avatar)
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Follow action')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Like button
                  _ActionButton(
                    icon: context
                            .watch<VideoProvider>()
                            .isLiked(widget.videoItem.path)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: context
                            .watch<VideoProvider>()
                            .isLiked(widget.videoItem.path)
                        ? Colors.red
                        : Colors.white,
                    label: '0', // placeholder count
                    onTap: () {
                      context
                          .read<VideoProvider>()
                          .toggleLike(widget.videoItem.path);
                    },
                  ),
                  const SizedBox(height: 24),
                  // Save (favorite) button
                  _ActionButton(
                    icon: context
                            .watch<VideoProvider>()
                            .isSaved(widget.videoItem.path)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: context
                            .watch<VideoProvider>()
                            .isSaved(widget.videoItem.path)
                        ? Colors.yellow
                        : Colors.white,
                    label: '',
                    onTap: () {
                      context
                          .read<VideoProvider>()
                          .toggleSave(widget.videoItem.path);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Description, hashtag, community (bottom center) with gradient background
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description with fade after 3 lines
                  DescriptionFadeText(text: widget.videoItem.description),
                  const SizedBox(height: 8),
                  // Hashtag
                  Text(
                    widget.videoItem.hashtag.isNotEmpty
                        ? '#${widget.videoItem.hashtag}'
                        : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Community
                  Text(
                    widget.videoItem.community,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          if (label.isNotEmpty)
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ])),
        ],
      ),
    );
  }
}
