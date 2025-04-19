import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(PizzaGameApp());
}

class PizzaGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pizza Master 9000',
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
  int pepperoniCount = 0;
  bool comboActive = false;
  int comboCount = 0;
  Timer? comboTimer;
  String fakeOrder = '';
  String gameMode = 'Normal';
  Timer? autoBakeTimer;
  int secondsLeft = 60;
  late Timer countdown;

  final List<String> fakeOrders = [
    '10 pepperonis!',
    'Minimum 5 slices!',
    'Spam it with pepperoni!',
    'Max 3 slices!',
    'Make it symmetrical 😳',
    'Make it chaotic 🔥'
  ];

  @override
  void initState() {
    super.initState();
    fakeOrder = fakeOrders[Random().nextInt(fakeOrders.length)];
    startCountdown();
  }

  void startCountdown() {
    countdown = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isBaked) {
        timer.cancel();
        return;
      }
      setState(() {
        secondsLeft--;
      });
      if (secondsLeft <= 0) {
        startBaking(forced: true);
        timer.cancel();
      }
    });
  }

  void triggerCombo() {
    comboTimer?.cancel();
    setState(() {
      comboCount++;
      comboActive = true;
    });
    comboTimer = Timer(Duration(seconds: 2), () {
      setState(() {
        comboActive = false;
        comboCount = 0;
      });
    });
  }

  void startBaking({bool forced = false}) {
    if (isBaking || isBaked) return;

    setState(() {
      isBaking = true;
      bakeProgress = 0.0;
    });

    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 50));
      setState(() {
        bakeProgress += 0.03;
      });
      if (bakeProgress >= 1.0) {
        setState(() {
          isBaking = false;
          isBaked = true;
        });
        showResults(forced: forced);
        return false;
      }
      return true;
    });
  }

  void showResults({bool forced = false}) {
    String message = '';

    if (pepperoniCount == 0) {
      message = 'Bro you didn’t put ANY toppings 😭';
    } else if (pepperoniCount < 3) {
      message = 'That’s a sad pizza... 🍕';
    } else if (pepperoniCount >= 15) {
      message = 'That’s a CRIME against PIZZAS 🔥';
    } else if (comboCount >= 3) {
      message = '🔥 COMBO GOD 🔥';
    } else {
      message = 'Solid slice chef 😎';
    }

    if (forced) message += '\n\n(Time’s up!)';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Pizza Results"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void resetPizza() {
    countdown.cancel();
    setState(() {
      pepperoniPositions.clear();
      isBaking = false;
      isBaked = false;
      bakeProgress = 0.0;
      pepperoniCount = 0;
      comboCount = 0;
      secondsLeft = 60;
      fakeOrder = fakeOrders[Random().nextInt(fakeOrders.length)];
    });
    startCountdown();
  }

  void addPepperoni(Offset dropOffset, BuildContext context) {
    if (isBaked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("TOO LATE! It’s already baked 💀")),
      );
      return;
    }

    final box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(dropOffset);
    setState(() {
      pepperoniPositions.add(localOffset);
      pepperoniCount++;
    });

    triggerCombo();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🧀 *SIZZLE*")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text('🍕 Pizza Master 9000'),
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

          // Draggable pepperoni
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

          // Baking progress bar
          if (isBaking)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('🔥 Baking in progress...'),
                    SizedBox(height: 8),
                    LinearProgressIndicator(value: bakeProgress),
                  ],
                ),
              ),
            ),

          // Game HUD
          Positioned(
            top: 80,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("🧂 Pepperoni: $pepperoniCount",
                    style: TextStyle(fontSize: 16)),
                Text("🧠 Mode: $gameMode", style: TextStyle(fontSize: 16)),
                Text("📝 Order: $fakeOrder", style: TextStyle(fontSize: 16)),
                Text("⏱️ Time: $secondsLeft",
                    style: TextStyle(
                      fontSize: 16,
                      color: secondsLeft <= 10 ? Colors.red : Colors.black,
                    )),
                if (comboActive)
                  Text("🔥 COMBO x$comboCount!", style: TextStyle(fontSize: 18)),
              ],
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
                onPressed: isBaked ? null : () => startBaking(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
