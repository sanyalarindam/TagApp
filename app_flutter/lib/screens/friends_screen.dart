import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Friends')),
        body: Center(child: Text('Your tag inbox will appear here')),
      ),
    );
  }
}
