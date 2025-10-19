import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/video_provider.dart';
import './_description_fade_text.dart';
import './video_feed_item.dart';
import '../services/backend_api.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingFromBackend = false;
  List<VideoItem> _explore = [];
  String? _exploreError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        // Rebuild to reflect selected state when swiping between tabs
        if (mounted) setState(() {});
      });
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoadingFromBackend = true);
    try {
      final provider = context.read<VideoProvider>();
      await provider.loadFromBackend(BackendApi.instance.currentUserId);
    } catch (e) {
      print('Error loading posts: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFromBackend = false);
    }
  }

  Future<void> _loadExplore() async {
    setState(() {
      _exploreError = null;
    });
    try {
      final api = BackendApi.instance;
      final posts = await api.getAllPosts();
      final items = posts.map(api.videoItemFromPost).toList();
      if (!mounted) return;
      setState(() {
        _explore = items;
      });
      // Cache items so likes/saves show up in Profile
      context.read<VideoProvider>().cacheItems(items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exploreError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If auth just became ready/authenticated, ensure posts are loaded
    final auth = context.watch<AuthProvider>();
    if (auth.isReady &&
        auth.isAuthenticated &&
        !_isLoadingFromBackend &&
        context.watch<VideoProvider>().myUploads.isEmpty) {
      // Trigger a load in the next microtask to avoid setState during build
      Future.microtask(() => _loadUserPosts());
    }
    return Scaffold(
      body: Stack(
        children: [
          // Content: Tab views for Explore and Search
          Positioned.fill(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Explore Tab - TikTok-style vertical scroll
                Builder(
                  builder: (context) {
                    // Ensure explore is loaded
                    if (_explore.isEmpty && _exploreError == null) {
                      // Fire and forget; the next build will render when set
                      Future.microtask(_loadExplore);
                    }

                    if (_exploreError != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.grey, size: 36),
                              const SizedBox(height: 12),
                              const Text('Failed to load Explore feed'),
                              const SizedBox(height: 8),
                              Text(_exploreError!,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _loadExplore,
                                  child: const Text('Retry')),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_explore.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return RefreshIndicator(
                      onRefresh: _loadExplore,
                      child: PageView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        itemCount: _explore.length,
                        itemBuilder: (_, i) {
                          final video = _explore[i];
                          return VideoFeedItem(videoItem: video);
                        },
                      ),
                    );
                  },
                ),
                // Search Tab
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Search',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Find challenges, users, or communities',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Overlay: Gradient header with white text buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TopTabButton(
                    label: 'Explore',
                    selected: _tabController.index == 0,
                    onTap: () => _tabController.animateTo(0),
                  ),
                  const SizedBox(width: 16),
                  _TopTabButton(
                    label: 'Search',
                    selected: _tabController.index == 1,
                    onTap: () => _tabController.animateTo(1),
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

// Small top buttons for Explore/Search with white text
class _TopTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTabButton({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withOpacity(selected ? 0.9 : 0.4), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// TikTok-style video feed item with side buttons
class _VideoFeedItem extends StatefulWidget {
  final VideoItem videoItem;
  const _VideoFeedItem({Key? key, required this.videoItem}) : super(key: key);

  @override
  State<_VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<_VideoFeedItem> {
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
          // Video player (full width, centered vertically)
          Center(
            child: _isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
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

// Reusable action button widget
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
