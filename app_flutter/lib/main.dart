import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/video_provider.dart';
import 'screens/home_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';

// Placeholder for communities screen
class CommunitiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Communities')),
      body: Center(child: Text('Your communities and discover new ones here.')),
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
