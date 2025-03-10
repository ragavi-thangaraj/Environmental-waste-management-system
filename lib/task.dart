import 'dart:async';

import 'package:ease/task2.dart';
import 'package:ease/task3.dart';
import 'package:ease/task4.dart';
import 'package:ease/task5.dart';
import 'package:ease/task6.dart';
import 'package:ease/task7.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final int level;
  bool isUnlocked;
  bool isCompleted;
  Task({required this.level, this.isUnlocked = false, this.isCompleted = false});
}
class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);
  @override
  _TaskPageState createState() => _TaskPageState();
}
class _TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  // Example: 10 tasks
  List<Task> tasks = List.generate(
    10,
        (index) => Task(level: index + 1),
  );

  StreamSubscription? _verifySubscription;
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _updateUnlockedLevels(); // Initial Firestore check.
    _verifySubscription = FirebaseFirestore.instance
        .collection('verify')
        .snapshots()
        .listen((_) => _updateUnlockedLevels());

    // Animate background gradient
    _bgAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _verifySubscription?.cancel();
    _bgAnimationController.dispose();
    super.dispose();
  }

  /// Fetches tasks from Firestore and unlocks levels dynamically.
  Future<void> _updateUnlockedLevels() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('verify')
        .where('userId',isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('status', isEqualTo: 'Confirmed')
        .get();

    int maxConfirmedLevel = 0;
    for (var doc in snapshot.docs) {
      int docLevel = (doc['level'] as num?)?.toInt() ?? 0;
      if (docLevel > maxConfirmedLevel) {
        maxConfirmedLevel = docLevel;
      }
    }

    setState(() {
      for (var task in tasks) {
        if (task.level <= maxConfirmedLevel) {
          // Completed levels.
          task.isUnlocked = true;
          task.isCompleted = true;
        } else if (task.level == maxConfirmedLevel + 1) {
          // Next level unlocked.
          task.isUnlocked = true;
          task.isCompleted = false;
        } else {
          task.isUnlocked = false;
          task.isCompleted = false;
        }
      }
    });
  }

  Future<void> _onLevelSelected(int level) async {
    Task selectedTask = tasks.firstWhere((task) => task.level == level);
    if (!selectedTask.isUnlocked) {
      _showLockedLevelDialog();
      return;
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Simulate delay
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);

    PageRouteBuilder? route;

    if (level == 6) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      // Check if a submission for level 3 already exists.
      final submissionSnapshot = await FirebaseFirestore.instance
          .collection("verify")
          .where("userId", isEqualTo: currentUser.uid)
          .where("level", isEqualTo: 1)
          .get();

      if (submissionSnapshot.docs.isNotEmpty) {
        final doc = submissionSnapshot.docs.first;
        final status = doc.data()["status"];
        if (status == "Not Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildReviewDialogContent(context),
            ),
          );
          return;
        } else if (status == "Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildCustomConfirmationDialog(context),
            ),
          );
          return;
        }
      } else {
        route = PageRouteBuilder(
          pageBuilder: (_, __, ___) => TrashCollectGame(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        );
      }
    } else if (level == 5) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      // Check if a submission for level 3 already exists.
      final submissionSnapshot = await FirebaseFirestore.instance
          .collection("verify")
          .where("userId", isEqualTo: currentUser.uid)
          .where("level", isEqualTo: 5)
          .get();

      if (submissionSnapshot.docs.isNotEmpty) {
        final doc = submissionSnapshot.docs.first;
        final status = doc.data()["status"];
        if (status == "Not Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildReviewDialogContent(context),
            ),
          );
          return;
        } else if (status == "Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildCustomConfirmationDialog(context),
            ),
          );
          return;
        }
      } else {
        route = PageRouteBuilder(
          pageBuilder: (_, __, ___) => TrashCollectGame(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        );
      }
    } else if (level == 3) {
      // Get the current user.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      // Check if a submission for level 3 already exists.
      final submissionSnapshot = await FirebaseFirestore.instance
          .collection("verify")
          .where("userId", isEqualTo: currentUser.uid)
          .where("level", isEqualTo: 3)
          .get();

      if (submissionSnapshot.docs.isNotEmpty) {
        final doc = submissionSnapshot.docs.first;
        final status = doc.data()["status"];
        if (status == "Not Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildReviewDialogContent(context),
            ),
          );
          return;
        } else if (status == "Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildCustomConfirmationDialog(context),
            ),
          );
          return;
        }
      } else {
        // No previous submission: navigate to the Mini Garden task screen.
        route = PageRouteBuilder(
          pageBuilder: (_, __, ___) => MiniGardenTaskScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        );
      }
    } else if (level == 4) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      // Check if a submission for level 3 already exists.
      final submissionSnapshot = await FirebaseFirestore.instance
          .collection("verify")
          .where("userId", isEqualTo: currentUser.uid)
          .where("level", isEqualTo: 4)
          .get();

      if (submissionSnapshot.docs.isNotEmpty) {
        final doc = submissionSnapshot.docs.first;
        final status = doc.data()["status"];
        if (status == "Not Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildReviewDialogContent(context),
            ),
          );
          return;
        } else if (status == "Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildCustomConfirmationDialog(context),
            ),
          );
          return;
        }
      }
      // Navigate to the Recycling Sorting Game screen.
      else {
      route = PageRouteBuilder(
        pageBuilder: (_, __, ___) => TrashCollectGame(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );
    }
    }
    else if (level == 2) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      // Check existing submission in 'verify' collection
      final submissionSnapshot = await FirebaseFirestore.instance
          .collection("verify")
          .where("userId", isEqualTo: currentUser.uid)
          .where("level", isEqualTo: 2)
          .get();

      if (submissionSnapshot.docs.isNotEmpty) {
        final doc = submissionSnapshot.docs.first;
        final status = doc.data()["status"];

        if (status == "Not Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildReviewDialogContent(context),
            ),
          );
          return;
        } else if (status == "Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildCustomConfirmationDialog(context),
            ),
          );
          return;
        }
      }

      // ✅ Open EcoFriendlyArtScreen directly without extra function call
      route = PageRouteBuilder(
        pageBuilder: (_, __, ___) => TrashCollectGame(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );
    }
    else if (level == 7)
    {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User not logged in.")),
          );
          return;
        }

        // Check if a submission for level 3 already exists.
        final submissionSnapshot = await FirebaseFirestore.instance
            .collection("verify")
            .where("userId", isEqualTo: currentUser.uid)
            .where("level", isEqualTo: 7)
            .get();

        if (submissionSnapshot.docs.isNotEmpty) {
          final doc = submissionSnapshot.docs.first;
          final status = doc.data()["status"];
          if (status == "Not Confirmed") {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: _buildReviewDialogContent(context),
              ),
            );
            return;
          } else if (status == "Confirmed") {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: _buildCustomConfirmationDialog(context),
              ),
            );
            return;
          }
        } else {
          route = PageRouteBuilder(
            pageBuilder: (_, __, ___) => BeachCleanupGame(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          );
        }
      }
    else if (level == 1) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      // Check existing submission in 'verify' collection
      final submissionSnapshot = await FirebaseFirestore.instance
          .collection("verify")
          .where("userId", isEqualTo: currentUser.uid)
          .where("level", isEqualTo: 1)
          .get();

      if (submissionSnapshot.docs.isNotEmpty) {
        final doc = submissionSnapshot.docs.first;
        final status = doc.data()["status"];

        if (status == "Not Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildReviewDialogContent(context),
            ),
          );
          return;
        } else if (status == "Confirmed") {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildCustomConfirmationDialog(context),
            ),
          );
          return;
        }
      }

      // ✅ Open EcoFriendlyArtScreen directly without extra function call
      route = PageRouteBuilder(
        pageBuilder: (_, __, ___) => RecyclingSortingGameScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );
    }
    else {
      // For future levels (other than 1, 2, 3, or 4)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Level $level selected - coming soon.")),
      );
      return;
    }

    // Only push the route if it has been assigned.
    if (route != null) {
      Navigator.push(context, route);
    }
  }

  Widget _buildReviewDialogContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage("lib/assets/ease.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.4),
            BlendMode.dstATop,
          ),
        ),
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top,
            size: 80,
            color: Colors.green.shade700,
          ),
          SizedBox(height: 10),
          Text(
            "Submission Under Review",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "Your Mini Garden task submission is currently under verification. Please check back later for confirmation.",
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              "OK",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCustomConfirmationDialog(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Background image with a white fading effect.
        image: DecorationImage(
          image: AssetImage("lib/assets/ease.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.6),
            BlendMode.dstATop,
          ),
        ),
        // A subtle green gradient overlay.
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Task Confirmed!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "Thank you for being a part of keeping our environment tidy and clean. Your points have been added to your piggy bank. Enjoy your day!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              "OK",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showLockedLevelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Level Locked"),
        content: const Text("Complete previous levels to unlock this one."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Main build method with animated background.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fading background image.
          FadingBackground(),
          SafeArea(
            child: Column(
              children: [
                const PremiumAppBar(),
                Expanded(
                  child: CandyMap(
                      tasks: tasks, onLevelSelected: _onLevelSelected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
/// Animated Premium App Bar with an animated title.
class PremiumAppBar extends StatelessWidget {
  const PremiumAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade500, Colors.lightGreen.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: const Text(
                  'Green Journey',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
/// Scrollable map with animated level circles.
class CandyMap extends StatelessWidget {
  final List<Task> tasks;
  final Function(int) onLevelSelected;
  const CandyMap({Key? key, required this.tasks, required this.onLevelSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Offset> levelPositions = _calculateLevelPositions(context, tasks.length);
    final totalHeight = (tasks.length * 250).toDouble();

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        height: totalHeight,
        child: Stack(
          children: [
            // Custom path behind circles
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, totalHeight),
              painter: PremiumPathPainter(levelPositions),
            ),
            // Animated level circles
            for (int i = 0; i < tasks.length; i++)
              Positioned(
                left: levelPositions[i].dx,
                top: levelPositions[i].dy,
                child: GestureDetector(
                  onTap: () => onLevelSelected(tasks[i].level),
                  child: LevelCircle(task: tasks[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Offset> _calculateLevelPositions(BuildContext context, int count) {
    double leftX = 40;
    double rightX = MediaQuery.of(context).size.width - 120;
    double startY = 50;
    double verticalSpacing = 200;

    List<Offset> positions = [];
    for (int i = 0; i < count; i++) {
      bool isEven = i % 2 == 0;
      double x = isEven ? leftX : rightX;
      double y = startY + i * verticalSpacing;
      positions.add(Offset(x, y));
    }
    return positions;
  }
}
/// Custom path painter with a smooth spline.
class PremiumPathPainter extends CustomPainter {
  final List<Offset> positions;
  PremiumPathPainter(this.positions);

  Path _createSmoothPath(List<Offset> points) {
    Path path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      Offset p0 = i == 0 ? points[0] : points[i - 1];
      Offset p1 = points[i];
      Offset p2 = points[i + 1];
      Offset p3 = (i + 2 < points.length) ? points[i + 2] : p2;

      Offset cp1 = p1 + (p2 - p0) / 6;
      Offset cp2 = p2 - (p3 - p1) / 6;
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    List<Offset> offsetPositions =
    positions.map((p) => p + const Offset(40, 40)).toList();
    Path path = _createSmoothPath(offsetPositions);

    final Paint glowPaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final Paint gradientPaint = Paint()
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Colors.green, Colors.greenAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Paint highlightPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.8)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, gradientPaint);
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant PremiumPathPainter oldDelegate) => true;
}
/// LevelCircle widget with animated effects.
class LevelCircle extends StatefulWidget {
  final Task task;
  const LevelCircle({Key? key, required this.task}) : super(key: key);

  @override
  State<LevelCircle> createState() => _LevelCircleState();
}
class _LevelCircleState extends State<LevelCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOutBack,
        ));

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _animController,
          curve: Curves.easeIn,
        ));
  }

  @override
  void didUpdateWidget(covariant LevelCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task != widget.task) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.task.isCompleted
                ? Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.star,
                  size: 100,
                  color: Colors.amber,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                Text(
                  '${widget.task.level}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            )
                : Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: widget.task.isUnlocked
                      ? [Colors.lightGreen.shade400, Colors.green.shade800]
                      : [Colors.grey.shade300, Colors.grey.shade600],
                  stops: const [0.3, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.task.level}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (!widget.task.isUnlocked)
              EcoPulsatingLock(), // Assume this is a custom animated lock widget.
          ],
        ),
      ),
    );
  }
}

class FadingBackground extends StatefulWidget {
  @override
  _FadingBackgroundState createState() => _FadingBackgroundState();
}
class _FadingBackgroundState extends State<FadingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Adjust duration as desired.
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Start the fade in animation.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/ease.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class EcoPulsatingLock extends StatefulWidget {
  @override
  _EcoPulsatingLockState createState() => _EcoPulsatingLockState();
}

class _EcoPulsatingLockState extends State<EcoPulsatingLock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                  ],
                  center: Alignment.center,
                  radius: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.lock,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NeighborhoodLitterPatrolScreen extends StatefulWidget {
  @override
  _NeighborhoodLitterPatrolScreenState createState() => _NeighborhoodLitterPatrolScreenState();
}

class _NeighborhoodLitterPatrolScreenState extends State<NeighborhoodLitterPatrolScreen> {
  File? beforePhoto;
  File? afterPhoto;
  bool taskCompleted = false;
  bool isVerifying = false; // flag to display the waiting note
  final ImagePicker _picker = ImagePicker();

  // Variables to store location data for each photo.
  Position? beforePhotoPosition;
  Position? afterPhotoPosition;

  // Holds the verified record (if any) from Firestore.
  Map<String, dynamic>? _verificationRecord;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  /// Query Firestore to see if a document exists with the current userId,
  /// level 1 and status as "Confirmed".
  Future<void> _checkVerificationStatus() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('verify')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('status', isEqualTo: 'Confirmed')
          .where('level', isEqualTo: 1)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _verificationRecord = querySnapshot.docs.first.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error checking verification status: $e');
    }
  }

  /// Capture the current location.
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  /// Capture photo using camera and also store location data.
  Future<void> _capturePhoto(bool isBefore) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        Position currentPosition = await _getCurrentLocation();

        setState(() {
          if (isBefore) {
            beforePhoto = File(photo.path);
            beforePhotoPosition = currentPosition;
          } else {
            afterPhoto = File(photo.path);
            afterPhotoPosition = currentPosition;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  /// Verify that both photos (and their locations) exist, convert them to Base64,
  /// and store the data in Firestore under the "verify" collection.
  Future<void> _verifyAndMarkComplete() async {
    if (beforePhoto == null ||
        afterPhoto == null ||
        beforePhotoPosition == null ||
        afterPhotoPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please capture both before and after photos with location data.')),
      );
      return;
    }

    setState(() {
      isVerifying = true;
    });

    try {
      final beforeBytes = await beforePhoto!.readAsBytes();
      final afterBytes = await afterPhoto!.readAsBytes();
      final String beforePhotoBase64 = base64Encode(beforeBytes);
      final String afterPhotoBase64 = base64Encode(afterBytes);

      Map<String, dynamic> verifyData = {
        'level': 1,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        // Optionally add additional user details:
        'beforePhoto': beforePhotoBase64,
        'afterPhoto': afterPhotoBase64,
        'beforePhotoLatitude': beforePhotoPosition!.latitude,
        'beforePhotoLongitude': beforePhotoPosition!.longitude,
        'afterPhotoLatitude': afterPhotoPosition!.latitude,
        'afterPhotoLongitude': afterPhotoPosition!.longitude,
        'status': 'Not Confirmed',
        'points': 0,
        'completedAt': DateTime.now(),
      };

      await FirebaseFirestore.instance.collection('verify').add(verifyData);

      setState(() {
        taskCompleted = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving progress: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  Widget _buildPhotoSection(String label, File? photo, bool isBefore) {
    if (_verificationRecord != null) {
      // Retrieve Base64 image and location data from the verified record.
      String base64Str = isBefore ? _verificationRecord!['beforePhoto'] : _verificationRecord!['afterPhoto'];
      var imageBytes = base64Decode(base64Str);
      double latitude = isBefore ? _verificationRecord!['beforePhotoLatitude'] : _verificationRecord!['afterPhotoLatitude'];
      double longitude = isBefore ? _verificationRecord!['beforePhotoLongitude'] : _verificationRecord!['afterPhotoLongitude'];

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(vertical: 8),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Original functionality for capturing photos.
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: photo != null
                  ? Image.file(
                photo,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
                  : Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.camera_alt, size: 50, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 8),
            // Show capture button only if photo is not yet captured.
            if (photo == null)
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _capturePhoto(isBefore),
                  icon: Icon(Icons.camera, color: Colors.white),
                  label: Text(
                    isBefore ? 'Capture Before Photo' : 'Capture After Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            if (photo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isBefore
                      ? 'Location: ${beforePhotoPosition?.latitude.toStringAsFixed(4)}, ${beforePhotoPosition?.longitude.toStringAsFixed(4)}'
                      : 'Location: ${afterPhotoPosition?.latitude.toStringAsFixed(4)}, ${afterPhotoPosition?.longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a gradient for an environmental vibe.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.lightGreen.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Anchor header with an eco icon.
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade800, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.eco, color: Colors.white, size: 48),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Neighborhood Litter Patrol',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Task description.
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Task: Take 10–15 minutes for a quick walk around your neighborhood to pick up litter from sidewalks, parks, or near local shops.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Before and After photo sections.
                _buildPhotoSection("Before Photo", beforePhoto, true),
                _buildPhotoSection("After Photo", afterPhoto, false),
                SizedBox(height: 16),
                // If the task has already been verified, show the verification status.
                _verificationRecord != null
                    ? Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _verificationRecord!['status'] == 'Not Confirmed'
                              ? [Colors.deepOrange, Colors.orangeAccent]
                              : [Colors.lightGreen, Colors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                _verificationRecord!['status'] == 'Not Confirmed'
                                    ? Icons.hourglass_top
                                    : Icons.check_circle_outline,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _verificationRecord!['status'] == 'Not Confirmed'
                                    ? "Verification in Progress!\nOnce verified, points will be added to your piggy bank. Hold tight and keep up the great work!"
                                    : "Thanks for Completing this Task!\nStay motivated and keep shining in your community.",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                // Otherwise show a button to mark the task as completed.
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isVerifying ? null : () {
                    if (!taskCompleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Your progress is under verification please hold tight")),
                      );
                      _verifyAndMarkComplete();
                    }
                  },
                  child: Text(
                    "Mark Task as Completed",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                SizedBox(height: 16),
                // Display verification waiting note if needed.
                if (isVerifying)
                  Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          "Please hold on tight until we verify your progress.",
                          style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                else if (taskCompleted && _verificationRecord == null)
                  Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          "Great job! You have completed the task.",
                          style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}