import 'package:flutter/material.dart';

/// Simple placeholder pages — replace imports with your real pages if present.
/// Example: import '../pages/friends_page.dart'; import '../pages/explore_page.dart';
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
        child:
            Text('Friends', style: Theme.of(context).textTheme.headlineSmall));
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
        child:
            Text('Explore', style: Theme.of(context).textTheme.headlineSmall));
  }
}

/// HomeSection: PageView + BottomNavigationBar + animated transitions
class HomeSection extends StatefulWidget {
  const HomeSection({super.key});
  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // If your app already has a Scaffold for the Home section, move the
      // BottomNavigationBar into that Scaffold and use the PageView as the body.
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: const [
          FriendsPage(),
          ExplorePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        ],
      ),
    );
  }
}
