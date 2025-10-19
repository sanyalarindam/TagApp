import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import './_description_fade_text.dart';
import '../main.dart';
import '../services/backend_api.dart';

class VideoFeedItem extends StatefulWidget {
  final VideoItem videoItem;
  const VideoFeedItem({Key? key, required this.videoItem}) : super(key: key);

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

// Simple view model for comments rendering
class _ViewComment {
  final String author;
  final String text;
  final DateTime createdAt;
  _ViewComment(
      {required this.author, required this.text, required this.createdAt});
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _wasPlayingBeforeSheet = false;

  @override
  void initState() {
    super.initState();
    _initControllerForPath(widget.videoItem.path);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoItem.path != widget.videoItem.path) {
      // Re-init controller for new video path
      _controller.dispose();
      _isInitialized = false;
      _initControllerForPath(widget.videoItem.path);
    }
  }

  void _initControllerForPath(String path) {
    // Choose file or network controller based on path
    if (path.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _controller = VideoPlayerController.file(File(path));
    }
    _controller
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isInitialized = true);
        _controller.play();
      });
  }

  Future<void> _openComments() async {
    // Pause video when opening; remember state to resume later
    if (_isInitialized) {
      _wasPlayingBeforeSheet = _controller.value.isPlaying;
      await _controller.pause();
    }

    // Always refresh the post from backend before showing comments
    final provider = context.read<VideoProvider>();
    final videoItem = widget.videoItem;
    if (videoItem.id != null && videoItem.id!.isNotEmpty) {
      final api = BackendApi.instance;
      try {
        // Fetch latest post and update provider cache
        final posts = await api.getAllPosts();
        final post = posts.firstWhere(
          (p) => p['postId'] == videoItem.id,
          orElse: () => <String, dynamic>{},
        );
        if (post.isNotEmpty) {
          provider.cacheItems([api.videoItemFromPost(post)]);
        }
      } catch (e) {
        print('Failed to refresh post for comments: $e');
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height;
        final sheetHeight = height * 0.65; // roughly 3/5 to 2/3 of screen
        return SizedBox(
          height: sheetHeight,
          child: _CommentsSheet(videoItem: widget.videoItem),
        );
      },
    );

    // Resume if it was playing before
    if (_isInitialized && _wasPlayingBeforeSheet) {
      await _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use the freshest copy from provider (contains updated counts/states)
    final provider = context.watch<VideoProvider>();
    final currentItem = provider.currentFor(widget.videoItem);
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
                : const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(),
                    ),
                  ),
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
                    icon: provider.isLikedItem(currentItem)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: provider.isLikedItem(currentItem)
                        ? Colors.red
                        : Colors.white,
                    label: currentItem.likes.toString(),
                    onTap: () {
                      // Basic tap-throttle: disable re-tap while async call likely in-flight by brief delay
                      provider.toggleLikeFor(currentItem);
                    },
                  ),
                  const SizedBox(height: 24),
                  // Comments button
                  _ActionButton(
                    icon: Icons.comment,
                    color: Colors.white,
                    label: currentItem.comments.length.toString(),
                    onTap: _openComments,
                  ),
                  const SizedBox(height: 24),
                  // Save (favorite) button
                  _ActionButton(
                    icon: provider.isSavedItem(currentItem)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: provider.isSavedItem(currentItem)
                        ? Colors.yellow
                        : Colors.white,
                    label: '',
                    onTap: () {
                      provider.toggleSaveFor(currentItem);
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
                  // Community (clickable)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CommunityFeedScreen(
                              community: widget.videoItem.community),
                        ),
                      );
                    },
                    child: Text(
                      widget.videoItem.community,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
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
              color: Colors.black.withValues(alpha: 0.3),
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

class _CommentsSheet extends StatefulWidget {
  final VideoItem videoItem;
  const _CommentsSheet({Key? key, required this.videoItem}) : super(key: key);

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _textController = TextEditingController();

  DateTime _parseIso(String s) {
    if (s.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final currentItem = provider.currentFor(widget.videoItem);
    // Backend comments come with fields: username, text, createdAt (ISO)
    final backendComments = currentItem.comments;
    final localComments = provider.commentsFor(widget.videoItem.path);
    // Build a unified list for rendering
    final List<_ViewComment> comments = [
      ...backendComments.map((c) => _ViewComment(
            author: (c['username'] ?? 'Anonymous').toString(),
            text: (c['text'] ?? '').toString(),
            createdAt: _parseIso((c['createdAt'] ?? '').toString()),
          )),
      ...localComments.map((c) => _ViewComment(
            author: c.author,
            text: c.text,
            createdAt: c.createdAt,
          )),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Comments (${comments.length})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Comments list
          Expanded(
            child: comments.isEmpty
                ? const Center(
                    child: Text('No comments yet',
                        style: TextStyle(color: Colors.white60)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (ctx, i) {
                      final c = comments[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                              radius: 16, child: Icon(Icons.person, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.author,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(c.text,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                const SizedBox(height: 6),
                                Text(
                                  _timeAgo(c.createdAt),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: comments.length,
                  ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Input area
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _submit,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context
        .read<VideoProvider>()
        .addCommentToPost(widget.videoItem, 'You', text);
    _textController.clear();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
