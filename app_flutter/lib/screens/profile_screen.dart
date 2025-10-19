import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Simple local profile state (placeholder until wired to backend)
  String _username = 'Username';
  String _bio = 'Bio goes here';
  String _avatarUrl =
      'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=256&h=256';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        // Generic username and stats
        Text(_username,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text('@' + _username, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat('0', 'Following'),
            SizedBox(width: 24),
            _buildStat('0', 'Followers'),
            SizedBox(width: 24),
            _buildStat('0', 'Tags'),
          ],
        ),
        SizedBox(height: 12),
        Text(_bio, textAlign: TextAlign.center),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  username: _username,
                  bio: _bio,
                  avatarUrl: _avatarUrl,
                ),
              ),
            );
            if (result is Map) {
              setState(() {
                _username =
                    (result['username'] as String?)?.trim().isNotEmpty == true
                        ? result['username']
                        : _username;
                _bio = (result['bio'] as String?)?.trim().isNotEmpty == true
                    ? result['bio']
                    : _bio;
                _avatarUrl =
                    (result['avatarUrl'] as String?)?.trim().isNotEmpty == true
                        ? result['avatarUrl']
                        : _avatarUrl;
              });
            }
          },
          child: Text('Edit Profile'),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildVideoGrid(List<String> videos) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0, // square
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        return Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              color: Colors.black12,
              child: Image.network(videos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  Text('${(i + 1) * 1000}',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> myVideos = List.generate(
        6,
        (i) =>
            'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=256&h=256');
    List<String> likedVideos = List.generate(
        4,
        (i) =>
            'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=256&h=256');
    List<String> savedVideos = List.generate(
        3,
        (i) =>
            'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=256&h=256');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Column(
          children: [
            _buildProfileHeader(),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(icon: Icon(Icons.favorite)),
                Tab(icon: Icon(Icons.bookmark)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVideoGrid(myVideos),
                  _buildVideoGrid(likedVideos),
                  _buildVideoGrid(savedVideos),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
