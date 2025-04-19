import 'package:flutter/material.dart';

void main() {
  runApp(PizzaGameApp());
}

class PizzaGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pizza Making Game',
      debugShowCheckedModeBanner: false,
      home: PizzaGameScreen(),
    );
  }
}

class PizzaGameScreen extends StatefulWidget {
  @override
  _PizzaGameScreenState createState() => _PizzaGameScreenState();
}

class _PizzaGameScreenState extends State<PizzaGameScreen> {
  final List<Offset> pepperoniPositions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make Your Pizza!'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Stack(
        children: [
          // Pizza base
          Align(
            alignment: Alignment.center,
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.offset);
                setState(() {
                  pepperoniPositions.add(localOffset);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 300,
                  height: 300,
                  child: Image.asset('assets/pizza_base.png'),
                );
              },
            ),
          ),

          // Placed pepperonis
          ...pepperoniPositions.map((pos) {
            return Positioned(
              left: pos.dx - 25,
              top: pos.dy - 25,
              child: Image.asset(
                'assets/pepperoni.png',
                width: 50,
                height: 50,
              ),
            );
          }),

          // Draggable pepperoni
          Positioned(
            bottom: 50,
            left: 50,
            child: Draggable<String>(
              data: 'pepperoni',
              feedback: Image.asset('assets/pepperoni.png', width: 50),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: Image.asset('assets/pepperoni.png', width: 50),
              ),
              child: Image.asset('assets/pepperoni.png', width: 50),
            ),
          ),
        ],
      ),
    );
  }
}
