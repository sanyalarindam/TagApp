import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/video_provider.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/video_feed_item.dart';

class InboxScreen extends StatelessWidget {
  final List<Map<String, String>> _messages = const [
    {
      'username': 'Username',
      'action': 'Tagged you!',
      'hashtag': '#Backflip',
      'time': '3d',
    },
    {
      'username': 'Username',
      'action': 'Responded to your tag!',
      'hashtag': '#Rapp Snitches Lick',
      'time': '4d',
    },
    {
      'username': 'Username',
      'action': 'Tagged you!',
      'hashtag': '#Front flip',
      'time': '3w',
    },
  ];

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
            Expanded(
              child: ListView.separated(
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black),
                                      children: [
                                        TextSpan(
                                            text: msg['username'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text: ' ${msg['action'] ?? ''}'),
                                      ],
                                    ),
                                  ),
                                  if ((msg['hashtag'] ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(msg['hashtag']!,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87)),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(msg['time']!,
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 70,
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('Preview',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for communities screen
class CommunityFeedScreen extends StatelessWidget {
  final String community;
  const CommunityFeedScreen({Key? key, required this.community})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videos = context
        .watch<VideoProvider>()
        .myUploads
        .where((v) => v.community.toLowerCase() == community.toLowerCase())
        .toList();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          videos.isEmpty
              ? Center(
                  child: Text('No videos in $community',
                      style: TextStyle(fontSize: 18, color: Colors.white)))
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  itemBuilder: (_, i) => VideoFeedItem(videoItem: videos[i]),
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
                          community,
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
                          decoration: BoxDecoration(
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

class CommunitiesScreen extends StatefulWidget {
  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _perPage = 6;
  final List<String> _allCommunities = [
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
    return ChangeNotifierProvider(
      create: (_) => VideoProvider(),
      child: MaterialApp(
        title: 'Tag',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MainTabs(),
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
