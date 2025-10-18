import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Explore')),
        body: Center(child: Text('Explore feed (public challenges) will appear here')),
      ),
    );
  }
}
