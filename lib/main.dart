import 'package:flutter/material.dart';

void main() {
  runApp(const KennyApp());
}

class KennyApp extends StatelessWidget {
  const KennyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kenny\'s App'),
        ),
        body: const Center(
          child: Text(
            'This is Kenny\'s iOS app test for Darla!',
            style: TextStyle(fontSize: 24, color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
