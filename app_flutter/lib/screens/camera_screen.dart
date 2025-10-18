import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Camera')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Camera UI placeholder. Recording and tagging flow to be implemented.'),
              SizedBox(height: 24),
              ElevatedButton(
                child: Text('Record'),
                onPressed: () {
                  // Will open recording flow in next iteration
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
