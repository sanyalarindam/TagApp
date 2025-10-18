import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Feed')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              Text('Friends | Explore', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 20),
              Expanded(
                child: Center(child: Text('Video feed will appear here')),
              )
            ],
          ),
        ),
      ),
    );
  }
}
