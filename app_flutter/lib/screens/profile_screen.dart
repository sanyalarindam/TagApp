import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import 'video_feed_item.dart';
import '../services/backend_api.dart';
import 'edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildStat(String value, String label) {
  return Column(
    children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _username = 'Username';
  String _bio = 'Bio goes here';
  String _avatarUrl =
      'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=256&h=256';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load current username from auth if available
    try {
      final name = BackendApi.instance.currentUsername;
      if (name.isNotEmpty) {
        _username = name;
      }
    } catch (_) {
      // not authenticated yet; keep placeholder
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            _buildProfileHeader(),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Uploads'),
                Tab(text: 'Liked'),
                Tab(text: 'Saved'),
              ],
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVideoGrid(context.watch<VideoProvider>().myUploads),
                  _buildVideoGrid(context.watch<VideoProvider>().likedVideos),
                  _buildVideoGrid(context.watch<VideoProvider>().savedVideos),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        SizedBox(height: 16),
        CircleAvatar(
          radius: 48,
          backgroundImage: NetworkImage(_avatarUrl),
        ),
        SizedBox(height: 8),
        Text(_username,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        SizedBox(height: 4),
        Text(_bio, style: TextStyle(color: Colors.grey, fontSize: 14)),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat(
                context.watch<VideoProvider>().myUploads.length.toString(),
                'Posts'),
            SizedBox(width: 24),
            _buildStat('100', 'Followers'),
            SizedBox(width: 24),
            _buildStat('50', 'Following'),
          ],
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            // Open EditProfileScreen and await result
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  username: _username,
                  bio: _bio,
                  avatarUrl: _avatarUrl,
                ),
              ),
            );
            if (result is Map<String, dynamic>) {
              final newUsername = result['username'] as String? ?? _username;
              final newBio = result['bio'] as String? ?? _bio;
              final newAvatar = result['avatarUrl'] as String? ?? _avatarUrl;
              setState(() {
                _username = newUsername;
                _bio = newBio;
                _avatarUrl = newAvatar;
              });
              // Update backend and refresh auth state
              try {
                final api = BackendApi.instance;
                await api.updateUser(api.currentUserId,
                    username: newUsername, bio: newBio);

                // Attempt to re-login with new username and previous password
                // (Assume password is unchanged and available in memory)
                // You may want to store the password securely in memory/session when user logs in
                final authProvider = context.read<AuthProvider>();
                final prefs = await SharedPreferences.getInstance();
                final prevPassword = prefs.getString('auth_password');
                if (prevPassword != null && prevPassword.isNotEmpty) {
                  try {
                    await api.login(
                        username: newUsername, password: prevPassword);
                    authProvider.signInSucceeded();
                  } catch (e) {
                    // If login fails, sign out and show error
                    await authProvider.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Re-login failed: $e')),
                    );
                  }
                } else {
                  // If password is not available, sign out and show info
                  await authProvider.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Please log in again with your new username.')),
                  );
                }
              } catch (e) {
                print('Failed to update profile: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile')),
                );
              }
            }
          },
          child: Text('Edit Profile'),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            // Clear any user-local state
            context.read<VideoProvider>().clear();
            await context.read<AuthProvider>().signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildVideoGrid(List<VideoItem> videos) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.video_collection, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No videos found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your videos will appear here',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _ProfileVideoFeedPage(
                  videos: videos,
                  initialIndex: i,
                ),
              ),
            );
          },
          child: Container(
            color: Colors.black12,
            child: Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileVideoFeedPage extends StatefulWidget {
  final List<VideoItem> videos;
  final int initialIndex;
  const _ProfileVideoFeedPage(
      {Key? key, required this.videos, required this.initialIndex})
      : super(key: key);

  @override
  State<_ProfileVideoFeedPage> createState() => _ProfileVideoFeedPageState();
}

class _ProfileVideoFeedPageState extends State<_ProfileVideoFeedPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            itemBuilder: (_, i) {
              return VideoFeedItem(videoItem: widget.videos[i]);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed duplicate build method and DefaultTabController with AppBar
}
