import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/video_provider.dart';
import 'screens/home_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/video_feed_item.dart';

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
    FriendsScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Tags'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
