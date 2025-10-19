import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/video_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/video_feed_item.dart';
import 'services/backend_api.dart';

class InboxScreen extends StatefulWidget {
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = BackendApi.instance;
      final msgs = await api.getInbox(api.currentUserId);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load inbox: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.inbox, size: 36, color: Colors.black),
                SizedBox(width: 12),
                Text('Inbox',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      return Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black26, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[300],
                                  child: const Icon(Icons.person,
                                      size: 32, color: Colors.black54),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text((() {
                                        final uname = msg['fromUsername'];
                                        final uid = msg['fromUserId'];
                                        final type =
                                            (msg['type']?.toString() ?? '')
                                                .toLowerCase();
                                        if (uname != null &&
                                            uname
                                                .toString()
                                                .trim()
                                                .isNotEmpty) {
                                          if (type == 'response') {
                                            return '$uname responded to your challenge';
                                          }
                                          return '$uname tagged you';
                                        } else if (uid != null &&
                                            uid.toString().trim().isNotEmpty) {
                                          return 'User $uid tagged you';
                                        } else {
                                          return 'Someone tagged you';
                                        }
                                      })(),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600)),
                                      if ((msg['postId'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        const SizedBox(height: 2),
                                      Text(msg['createdAt']?.toString() ?? '',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  // Fetch post details from backend
                                  final api = BackendApi.instance;
                                  final postId =
                                      msg['postId']?.toString() ?? '';
                                  if (postId.isEmpty) return;
                                  try {
                                    final posts = await api.getAllPosts();
                                    final post = posts.firstWhere(
                                      (p) => p['postId'] == postId,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    if (post.isNotEmpty) {
                                      final videoItem =
                                          api.videoItemFromPost(post);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PostDetailScreen(
                                            videoItem: videoItem,
                                            showChallengeButton:
                                                (msg['type']?.toString() ??
                                                        '') ==
                                                    'tag',
                                            inboxMessage: msg,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Failed to load post: $e')),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 90,
                                  height: 70,
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text('Preview',
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.black)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Post detail screen for inbox preview and challenge response
class PostDetailScreen extends StatelessWidget {
  final VideoItem videoItem;
  final bool showChallengeButton;
  final Map<String, dynamic>? inboxMessage;
  const PostDetailScreen(
      {Key? key,
      required this.videoItem,
      this.showChallengeButton = false,
      this.inboxMessage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Post Detail'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: VideoFeedItem(videoItem: videoItem),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showChallengeButton)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Take on the challenge!'),
                        onPressed: () async {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CameraScreen(
                                prefillHashtag: videoItem.hashtag,
                                prefillCommunity: videoItem.community,
                                responseToPostId: videoItem.id,
                                responseToUsername:
                                    inboxMessage?['fromUsername'],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityFeedScreen extends StatefulWidget {
  final String community;
  const CommunityFeedScreen({Key? key, required this.community})
      : super(key: key);

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  bool _loading = true;
  String? _error;
  List<VideoItem> _videos = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = BackendApi.instance;
      final posts = await api.getCommunityFeed(widget.community);
      final items = posts.map(api.videoItemFromPost).toList();
      // Cache items so like/save works across app
      // ignore: use_build_context_synchronously
      if (mounted) context.read<VideoProvider>().cacheItems(items);
      if (!mounted) return;
      setState(() {
        _videos = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.white70, size: 36),
                              const SizedBox(height: 12),
                              Text('Failed to load community feed',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _fetch,
                                  child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _videos.isEmpty
                        ? Center(
                            child: Text('No videos in ${widget.community}',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white)))
                        : _FeedPager(videos: _videos, onRefresh: _fetch),
          ),
          // Gradient header overlay with title and close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          widget.community,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.black,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPager extends StatefulWidget {
  final List<VideoItem> videos;
  final Future<void> Function() onRefresh;
  const _FeedPager({Key? key, required this.videos, required this.onRefresh})
      : super(key: key);
  @override
  State<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends State<_FeedPager> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: PageView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: (i) {},
        itemBuilder: (_, i) {
          return VideoFeedItem(videoItem: widget.videos[i]);
        },
      ),
    );
  }
}

class CommunitiesScreen extends StatefulWidget {
  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _perPage = 6;
  List<String> _allCommunities = [
    'Guitar',
    'Parkour',
    'Basketball',
    'Pickleball',
    'Dance',
    'Chemistry',
    'Chess',
    'Running',
    'Coding',
    'Cooking',
    'Photography',
    'Travel'
  ];

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    try {
      final api = BackendApi.instance;
      final remote = await api.listCommunities();
      // Merge and de-duplicate
      final set = {
        ..._allCommunities.map((e) => e.trim()),
        ...remote.map((e) => e.trim())
      }.where((s) => s.isNotEmpty).toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _allCommunities = set;
      });
    } catch (e) {
      // Keep defaults on failure; optionally show a toast
      debugPrint('Failed to load communities: $e');
    }
  }

  List<String> get _filteredCommunities {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allCommunities;
    return _allCommunities
        .where((c) => c.toLowerCase().contains(query))
        .toList();
  }

  List<String> get _pageCommunities {
    final filtered = _filteredCommunities;
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredCommunities.length / _perPage).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text('Communities',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            // Search bar styled like Explore/Profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                    hintText: 'Search communities',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: TextStyle(fontSize: 18),
                  onChanged: (_) => setState(() {
                    _currentPage = 1;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('My Communities',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            // Grid of communities styled like Profile/Explore
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1,
                  ),
                  itemCount: _pageCommunities.length,
                  itemBuilder: (ctx, i) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommunityFeedScreen(
                                  community: _pageCommunities[i]),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _pageCommunities[i],
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Pagination controls styled compact
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  ...List.generate(_totalPages, (i) {
                    final page = i + 1;
                    final selected = page == _currentPage;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _currentPage = page),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: selected ? Colors.grey[400] : Colors.white,
                            border: Border.all(color: Colors.black26, width: 1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              page.toString(),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 24),
                    onPressed: _currentPage < _totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(TagApp());
}

class TagApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Tag',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isAuthenticated ? MainTabs() : const SignInScreen();
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _doLogin(bool register) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = BackendApi.instance;
      if (register) {
        await api.register(
            username: _username.text.trim(), password: _password.text);
      } else {
        await api.login(
            username: _username.text.trim(), password: _password.text);
      }
      if (!mounted) return;
      context.read<AuthProvider>().signInSucceeded();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sign in to Tag',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 8),
              TextField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _doLogin(false),
                      child: _busy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _doLogin(true),
                      child: const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainTabs extends StatefulWidget {
  @override
  _MainTabsState createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    CommunitiesScreen(),
    CameraScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups), label: 'Communities'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt), label: 'Record'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
