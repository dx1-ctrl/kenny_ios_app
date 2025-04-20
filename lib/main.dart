import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(PizzaGameApp());

class PizzaGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PizzaMaster Ultra',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.orange[50],
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Courier', fontSize: 16),
        ),
      ),
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
            gameModeButton(context, 'Normal'),
            gameModeButton(context, 'Speed'),
            gameModeButton(context, 'Chaos'),
          ],
        ),
      ),
    );
  }

  Widget gameModeButton(BuildContext context, String mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PizzaGameScreen(mode: mode))),
        child: Text('$mode Mode'),
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
  int score = 0;
  int bestScore = 0;
  bool customCrust = false;

  final List<String> fakeOrders = [
    "Use 10 slices! 🍕",
    "Only 3 toppings!",
    "Cover the center!",
    "Don't touch the center!",
    "Spam the edges!",
    "Be precise! 🧠"
  ];

  @override
  void initState() {
    super.initState();
    applyModeSettings();
    fakeOrder = (fakeOrders..shuffle()).first;
    predictRating();
    startCountdown();
    loadBestScore();
  }

  Future<void> loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('bestPizzaScore') ?? 0;
    });
  }

  Future<void> saveBestScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bestPizzaScore', newScore);
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
        score = calculateScore();
        if (score > bestScore) {
          bestScore = score;
          saveBestScore(score);
        }
        showResults(forced: forced);
        return false;
      }
      return true;
    });
  }

  int calculateScore() {
    int base = pepperoniCount * 10;
    int centerHits = pepperoniPositions.where((pos) {
      final dx = pos.dx - pizzaCenter.dx;
      final dy = pos.dy - pizzaCenter.dy;
      return sqrt(dx * dx + dy * dy) < 50;
    }).length;
    int edgeBonus = pepperoniPositions.where((pos) {
      final dx = pos.dx - pizzaCenter.dx;
      final dy = pos.dy - pizzaCenter.dy;
      double d = sqrt(dx * dx + dy * dy);
      return d > 90 && d < 140;
    }).length;

    int total = base + (comboCount * 15) + (centerHits * 5) + (edgeBonus * 3);
    if (widget.mode == 'Speed') total += 20;
    if (widget.mode == 'Chaos') total += 40;
    return total;
  }

  void showResults({bool forced = false}) {
    String message = 'Score: $score\nBest Pizza Ever: $bestScore';
    message += '\n\n';
    if (pepperoniCount == 0) message += 'Bro... ZERO toppings.';
    else if (pepperoniCount < 3) message += 'Undercooked vibe 😕';
    else if (pepperoniCount > 18) message += 'This is chaos incarnate.';
    else message += 'Honestly, this looks great chef 👩‍🍳';

    if (forced) message += '\n\n(Time\'s up!)';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Results - ${widget.mode} Mode"),
        content: Text(message.replaceAll('\n', '\n')),
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
      appBar: AppBar(
        title: Text('PizzaMaster Ultra - ${widget.mode} Mode'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Reset Pizza',
            onPressed: resetPizza,
          ),
          IconButton(
            icon: Icon(customCrust ? Icons.blur_on : Icons.blur_off),
            tooltip: 'Toggle Custom Crust',
            onPressed: () => setState(() => customCrust = !customCrust),
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
                    decoration: BoxDecoration(
                      border: customCrust
                          ? Border.all(color: Colors.redAccent, width: 6, style: BorderStyle.solid)
                          : null,
                      borderRadius: BorderRadius.circular(150),
                    ),
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
                  Text("🔮 Prediction: $prediction", style: TextStyle(fontStyle: FontStyle.italic)),
                  SizedBox(height: 6),
                  Text("🏆 Best Pizza: $bestScore", style: TextStyle(fontWeight: FontWeight.bold))
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
