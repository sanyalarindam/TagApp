import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('User posts and stats will appear here')),
      ),
    );
  }
}
