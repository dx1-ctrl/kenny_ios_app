// PizzaMaster Ultra v1.2.0 - Game Modes + Advanced Scoring
// Now includes: accuracy rewards, mode-based scoring, bake prediction, and failure conditions

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(PizzaGameApp());

class PizzaGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PizzaMaster Ultra',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: ModeSelector(),
    );
  }
}

class ModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Game Mode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PizzaGameScreen(mode: 'Normal'))),
              child: Text('Normal Mode'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PizzaGameScreen(mode: 'Speed'))),
              child: Text('Speed Mode (30s)'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PizzaGameScreen(mode: 'Chaos'))),
              child: Text('Chaos Mode (randomized!)'),
            ),
          ],
        ),
      ),
    );
  }
}

class PizzaGameScreen extends StatefulWidget {
  final String mode;
  PizzaGameScreen({required this.mode});

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
  int secondsLeft = 60;
  late Timer countdown;
  double pizzaRadius = 150;
  Offset pizzaCenter = Offset.zero;
  String prediction = '';

  final List<String> fakeOrders = [
    'Use 10 slices! 🍕',
    'Only 3 toppings!',
    'Cover the center!',
    "Don't touch the center!",
    'Spam the edges!',
    'Be precise! 🧠'
  ];

  @override
  void initState() {
    super.initState();
    applyModeSettings();
    fakeOrder = (fakeOrders..shuffle()).first;
    predictRating();
    startCountdown();
  }

  void applyModeSettings() {
    if (widget.mode == 'Speed') secondsLeft = 30;
    else if (widget.mode == 'Chaos') secondsLeft = Random().nextInt(20) + 40;
    else secondsLeft = 60;
  }

  void startCountdown() {
    countdown = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isBaked) timer.cancel();
      setState(() => secondsLeft--);
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
    predictRating();
  }

  void startBaking({bool forced = false}) {
    if (isBaking || isBaked) return;
    setState(() {
      isBaking = true;
      bakeProgress = 0.0;
    });
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 50));
      setState(() => bakeProgress += 0.03);
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

  void predictRating() {
    if (pepperoniCount == 0) {
      prediction = 'This will be SAD 😭';
    } else if (pepperoniCount >= 12) {
      prediction = 'Overloaded!! Might burn!';
    } else if (comboCount >= 3) {
      prediction = '🔥 Combo King Pizza';
    } else {
      prediction = 'Solid vibes so far 👍';
    }
  }

  void showResults({bool forced = false}) {
    int centerHits = pepperoniPositions.where((pos) {
      final dx = pos.dx - pizzaCenter.dx;
      final dy = pos.dy - pizzaCenter.dy;
      final dist = sqrt(dx * dx + dy * dy);
      return dist < 50;
    }).length;

    String message = '';
    if (pepperoniCount == 0) message = 'Bro... ZERO toppings.';
    else if (pepperoniCount < 3) message = 'Undercooked vibe 😕';
    else if (pepperoniCount > 18) message = 'This is chaos incarnate.';
    else if (centerHits < 2) message = 'Center looks empty.';
    else if (centerHits > 5) message = 'Center is OVERLOADED.';
    else if (comboCount >= 3) message = '🔥 You nailed the combo zone!';
    else message = 'Honestly, this looks great chef 🧑‍🍳';

    if (widget.mode == 'Speed') message += '\n(Speed Mode Bonus Applied)';
    if (widget.mode == 'Chaos') message += '\n(You survived Chaos Mode 😮‍💨)';
    if (forced) message += '\n\n(Time's up!)';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Results - ${widget.mode} Mode"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
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
      applyModeSettings();
      fakeOrder = (fakeOrders..shuffle()).first;
    });
    predictRating();
    startCountdown();
  }

  void addPepperoni(Offset dropOffset, BuildContext context) {
    if (isBaked) return;
    final box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(dropOffset);
    final dx = localOffset.dx - pizzaCenter.dx;
    final dy = localOffset.dy - pizzaCenter.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance <= pizzaRadius - 25) {
      setState(() {
        pepperoniPositions.add(localOffset);
        pepperoniCount++;
      });
      triggerCombo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text('PizzaMaster Ultra - ${widget.mode} Mode'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Reset Pizza',
            onPressed: resetPizza,
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          pizzaCenter = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          return Stack(children: [
            Align(
              alignment: Alignment.center,
              child: DragTarget<String>(
                onAcceptWithDetails: (details) => addPepperoni(details.offset, context),
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: 300,
                    height: 300,
                    child: Image.asset('assets/pizza_base.png'),
                  );
                },
              ),
            ),
            ...pepperoniPositions.map((pos) => Positioned(
              left: pos.dx - 25,
              top: pos.dy - 25,
              child: Image.asset('assets/pepperoni.png', width: 50),
            )),
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
            if (isBaking)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Baking in progress...'),
                      SizedBox(height: 8),
                      LinearProgressIndicator(value: bakeProgress),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 80,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pepperoni: $pepperoniCount", style: TextStyle(fontSize: 16)),
                  Text("Order: $fakeOrder", style: TextStyle(fontSize: 16)),
                  Text("Time: $secondsLeft", style: TextStyle(
                    fontSize: 16,
                    color: secondsLeft <= 10 ? Colors.red : Colors.black,
                  )),
                  if (comboActive)
                    Text("🔥 COMBO x$comboCount!", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 4),
                  Text("🔮 Prediction: $prediction", style: TextStyle(fontStyle: FontStyle.italic))
                ],
              ),
            ),
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
          ]);
        },
      ),
    );
  }
}
