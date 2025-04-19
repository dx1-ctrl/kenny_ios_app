import 'package:flutter/material.dart';

void main() {
  runApp(PizzaGameApp());
}

class PizzaGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🔥 Pizza Making Game 🔥',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepOrange),
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
  bool isBaking = false;
  bool isBaked = false;
  double bakeProgress = 0.0;

  void startBaking() {
    if (isBaked || isBaking) return;

    setState(() {
      isBaking = true;
      bakeProgress = 0.0;
    });

    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        bakeProgress += 0.02;
      });
      if (bakeProgress >= 1.0) {
        setState(() {
          isBaking = false;
          isBaked = true;
        });
        return false;
      }
      return true;
    });
  }

  void resetPizza() {
    setState(() {
      pepperoniPositions.clear();
      isBaking = false;
      isBaked = false;
      bakeProgress = 0.0;
    });
  }

  void addPepperoni(Offset dropOffset, BuildContext context) {
    if (isBaked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can't add toppings after baking!")),
      );
      return;
    }

    final box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(dropOffset);
    setState(() {
      pepperoniPositions.add(localOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🍕 Build Your Pizza 🍕'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Reset Pizza',
            onPressed: resetPizza,
          )
        ],
      ),
      body: Stack(
        children: [
          // Pizza Base
          Align(
            alignment: Alignment.center,
            child: DragTarget<String>(
              onAcceptWithDetails: (details) =>
                  addPepperoni(details.offset, context),
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

          // Baking progress
          if (isBaking)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Baking... 🍕🔥', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    LinearProgressIndicator(value: bakeProgress),
                  ],
                ),
              ),
            ),

          // Draggable Pepperoni
          Positioned(
            bottom: 100,
            left: 40,
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

          // Bake Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton.icon(
                icon: Icon(Icons.local_fire_department),
                label: Text(isBaked ? 'Pizza is Baked!' : 'Bake Pizza'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 20),
                ),
                onPressed: isBaked ? null : startBaking,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
