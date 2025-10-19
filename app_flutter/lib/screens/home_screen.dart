import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _tabController.index = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Feed'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: TabBar(
              controller: _tabController,
              onTap: _onTabTapped,
              tabs: [
                Tab(text: 'Friends'),
                Tab(text: 'Explore'),
              ],
              indicatorColor: Colors.white,
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            // Friends Feed
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Friends Feed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your friends\' tags will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Explore Feed
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Explore Feed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Public challenges will appear here',
                    style: TextStyle(color: Colors.grey),
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
