import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';


class TrashCollectGame extends StatefulWidget {
  @override
  _TrashCollectGameState createState() => _TrashCollectGameState();
}

class _TrashCollectGameState extends State<TrashCollectGame> {
  double playerX = 0.0;
  double playerY = 400.0;
  int collectedGarbage = 0;
  final int totalGarbage = 5;
  List<Offset> garbagePositions = [];

  @override
  void initState() {
    super.initState();
    _generateGarbagePositions();
  }

  void _generateGarbagePositions() {
    Random random = Random();
    garbagePositions = List.generate(
        totalGarbage,
            (index) =>
            Offset(random.nextDouble() * 300 + 50, random.nextDouble() * 500));
  }

  void _checkGarbageCollection() {
    setState(() {
      garbagePositions.removeWhere((garbage) {
        double distance = (garbage.dx - playerX).abs() +
            (garbage.dy - playerY).abs();
        if (distance < 50) {
          collectedGarbage++;
          return true; // Remove garbage if collected
        }
        return false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trash Collect Game',
      home: Scaffold(
        appBar: AppBar(title: Text("Park to Beach - Clean the Path")),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("lib/assets/park.jpg"), // Add park image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            ...garbagePositions.map((pos) => Positioned(
              left: pos.dx,
              top: pos.dy,
              child: Icon(Icons.delete, color: Colors.brown, size: 30),
            )),
            Positioned(
              left: playerX,
              top: playerY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    playerX += details.delta.dx;
                    playerY += details.delta.dy;
                    _checkGarbageCollection();
                  });
                },
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Image.asset(
                    "lib/assets/boy.jpg", // Add character image
                    width: 50,
                    height: 50,
                  ),
                  onPressed: () {},
                ),
              ),
            ),
            if (collectedGarbage == totalGarbage)
              Center(
                child: AlertDialog(
                  title: Text("Congratulations!"),
                  content: Text("You collected all the garbage! ⭐⭐⭐"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          collectedGarbage = 0;
                          _generateGarbagePositions();
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text("Play Again"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}