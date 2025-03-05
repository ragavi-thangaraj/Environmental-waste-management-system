import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class DisposalPage extends StatefulWidget {
  final String responseText;
  DisposalPage({required this.responseText});

  @override
  _DisposalPageState createState() => _DisposalPageState();
}

class _DisposalPageState extends State<DisposalPage> {
  late ConfettiController _confettiController;
  late String description;
  late List<String> tasks;
  Map<String, bool> completedTasks = {};
  int totalScore = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));

    Map<String, dynamic> extractedData = extractDescriptionAndTasks(widget.responseText);
    description = extractedData["description"];
    tasks = extractedData["tasks"];

    for (var task in tasks) {
      completedTasks[task] = false;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Map<String, dynamic> extractDescriptionAndTasks(String text) {
    List<String> lines = text.split("\n");
    String description = "";
    List<String> tasks = [];
    bool isTaskSection = false;

    for (String line in lines) {
      String lowerLine = line.toLowerCase().trim();

      // Check for the start of task section
      if (lowerLine.contains("tasks to be taken:") ||
          lowerLine.contains("task to be taken:") ||
          lowerLine.contains("tasks to be taken") ||
          lowerLine.contains("here's what you need to do")) {
        isTaskSection = true;
        if (line.contains(":")) {
          String possibleTasks = line.split(":")[1].trim();
          if (possibleTasks.isNotEmpty) tasks.add(possibleTasks);
        }
        continue;
      }

      if (isTaskSection) {
        if (RegExp(r"^\d+\.$").hasMatch(line.trim())) {
          continue;
        }
        if (RegExp(r"^\d+\.\s").hasMatch(line) ||
            RegExp(r"^[IVXLCDM]+\.\s").hasMatch(line) ||
            RegExp(r"^[-•]\s").hasMatch(line)) {
          tasks.add(line.substring(2).trim());
        } else if (line.isNotEmpty) {
          tasks.add(line.trim());
        }
      } else {
        description += line + " ";
      }
    }

    return {"description": description.trim(), "tasks": tasks};
  }

  int calculatePoints(String task) {
    List<String> eWasteItems = ["battery", "circuit", "mobile", "laptop", "chip"];
    return eWasteItems.any((item) => task.toLowerCase().contains(item)) ? 30 : 10;
  }

  void markTaskComplete(String task) {
    setState(() {
      if (!completedTasks[task]!) {
        completedTasks[task] = true;
        totalScore += calculatePoints(task);
      }
    });
  }

  void handleCompletion() async {
    if (completedTasks.values.every((completed) => completed)) {
      // Save the total score and task completion date to Firestore
      await _storeCompletionData();
      _confettiController.play();
      showSuccessDialog(context, totalScore);
    } else {
      showIncompleteDialog(context);
    }
  }
  Future<void> _storeCompletionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;

        // Safely get lastTaskCompletion
        final lastCompletionTimestamp = data['lastTaskCompletion'];
        DateTime? lastCompletion;

        if (lastCompletionTimestamp != null && lastCompletionTimestamp is Timestamp) {
          lastCompletion = lastCompletionTimestamp.toDate();
        }

        final currentStreak = data['streakCount'] ?? 0;
        final now = DateTime.now();

        int updatedStreak = currentStreak;

        // Check if lastCompletion exists before calculating streak
        if (lastCompletion != null) {
          if (now.difference(lastCompletion).inDays == 1) {
            updatedStreak += 1; // Continue streak
          } else if (now.difference(lastCompletion).inDays > 1) {
            updatedStreak = 1; // Reset streak
          }
        } else {
          updatedStreak = 1; // First-time completion, start streak
        }

        await userDoc.update({
          'totalScore': FieldValue.increment(totalScore),
          'lastTaskCompletion': now,
          'streakCount': updatedStreak,
        });
      }
    }
  }


  void showIncompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[800],
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: Image.network(
                  "https://cdn.dribbble.com/users/1993461/screenshots/8519252/media/1e383519e624dc7986f6af81745d2d0e.gif",
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Keep Going!",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Save Earth with small actions!",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSuccessDialog(BuildContext context, int totalScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[400],
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: Image.network(
                  "https://i.giphy.com/7bOnU4QwFgPa2Ta2HJ.webp",
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Great Job!",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "You earned $totalScore points!",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[400],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[900],
        title: Row(
          children: [
            SizedBox(width: 18),
            Icon(FontAwesomeIcons.recycle, color: Colors.white),
            SizedBox(width: 10),
            Text("Disposal Measures", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      // Stack with a continuous light-themed background using ease.jpg and a white gradient overlay
      body: Stack(
        children: [
          // Background image with gradient that starts pure white at the top and fades out
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/ease.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Confetti widget at the top center for celebrations
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              emissionFrequency: 0.02,
              numberOfParticles: 30,
              maxBlastForce: 50,
              minBlastForce: 20,
              gravity: 0.1,
            ),
          ),
          // Main content in a scrollable area
          Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title with Icon
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.leaf, color: Colors.green[800], size: 28),
                      SizedBox(width: 10),
                      Text("Why is this Important?",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Description text
                  Text(
                    description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 20),
                  // Tasks Section Title
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.tasks, color: Colors.green[800], size: 28),
                      SizedBox(width: 10),
                      Text("Tasks to Complete",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800])),
                    ],
                  ),
                  SizedBox(height: 10),
                  // List of tasks
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      String task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onTap: () => markTaskComplete(task),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: completedTasks[task]! ? Colors.greenAccent.withOpacity(0.7) : Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Icon(
                                completedTasks[task]! ? Icons.check_circle : Icons.circle_outlined,
                                color: Colors.green[800],
                                size: 26,
                              ),
                              title: Text(
                                task,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green[900]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  // Completion button centered
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: handleCompletion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.95),
                        foregroundColor: Colors.green[900],
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        shadowColor: Colors.black45,
                        elevation: 5,
                      ),
                      icon: Icon(Icons.done, size: 24),
                      label: Text("Mark as Complete", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
