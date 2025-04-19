import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag and Drop Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DragDropGame(),
    );
  }
}

class DragDropGame extends StatefulWidget {
  @override
  _DragDropGameState createState() => _DragDropGameState();
}

class _DragDropGameState extends State<DragDropGame> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drag and Drop Game'),
      ),
      body: Center(
        child: DragTarget<String>(
          onAccept: (data) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dropped $data')),
            );
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.blueAccent,
              child: Center(
                child: Text(
                  'Drop Here',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Draggable<String>(
        data: 'Item 1',
        child: Container(
          width: 50,
          height: 50,
          color: Colors.red,
          child: Center(
            child: Text(
              'Drag Me',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        feedback: Container(
          width: 50,
          height: 50,
          color: Colors.red.withOpacity(0.5),
          child: Center(
            child: Text(
              'Drag Me',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        childWhenDragging: Container(
          width: 50,
          height: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
}
