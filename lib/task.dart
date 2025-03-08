import 'dart:async';

import 'package:ease/task2.dart';
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

  Task({
    required this.level,
    this.isUnlocked = false,
    this.isCompleted = false,
  });
}

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  // Example: 10 tasks
  List<Task> tasks = List.generate(
    10,
        (index) => Task(level: index + 1, isUnlocked: false, isCompleted: false),
  );

  StreamSubscription? _verifySubscription;

  @override
  void initState() {
    super.initState();
    _updateUnlockedLevels(); // Initial Firestore check.
    _verifySubscription = FirebaseFirestore.instance
        .collection('verify')
        .snapshots()
        .listen((_) => _updateUnlockedLevels());
  }

  @override
  void dispose() {
    _verifySubscription?.cancel();
    super.dispose();
  }

  /// Fetches tasks from Firestore and unlocks levels dynamically.
  Future<void> _updateUnlockedLevels() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('verify')
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
          // Levels <= maxConfirmedLevel are completed.
          task.isUnlocked = true;
          task.isCompleted = true;
        } else if (task.level == maxConfirmedLevel + 1) {
          // The immediate next level is unlocked, but not completed.
          task.isUnlocked = true;
          task.isCompleted = false;
        } else {
          // All others remain locked.
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

    // Simulate a short delay
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    // Navigate to the correct screen
    if (level == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NeighborhoodLitterPatrolScreen()),
      );
    } else if (level == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UpcyclingChallengeScreen()),
      );
    } else {
      // Future implementation for higher levels
      print("Level $level selected - Future implementation pending.");
    }
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

  /// Main build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: FadingBackground()), // Your existing background
          SafeArea(
            child: Column(
              children: [
                _buildPremiumAppBar(context),
                Expanded(
                  child: _buildCandyMap(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A custom "premium" app bar with a gold-orange gradient.
  Widget _buildPremiumAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.lightGreen.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
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
              child: Text(
                'Green Journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Extra space
        ],
      ),
    );
  }

  /// Builds a single scrollable "map" with a zigzag path of levels.
  Widget _buildCandyMap(BuildContext context) {
    // Calculate each level's position in a zigzag pattern.
    List<Offset> levelPositions = _calculateLevelPositions(tasks.length);

    // The total height of the stack should fit all levels plus spacing.
    final totalHeight = (tasks.length * 250).toDouble();

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        height: totalHeight,
        child: Stack(
          children: [
            // Draw the connecting path behind the circles
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, totalHeight),
              painter: _PremiumPathPainter(levelPositions),
            ),
            // Place each level circle at its position
            for (int i = 0; i < tasks.length; i++)
              Positioned(
                left: levelPositions[i].dx,
                top: levelPositions[i].dy,
                child: GestureDetector(
                  onTap: () => _onLevelSelected(tasks[i].level),
                  child: LevelCircle(task: tasks[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Generates a list of Offsets for each level in a left-right zigzag.
  List<Offset> _calculateLevelPositions(int count) {
    // Adjust these to control layout
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

class _PremiumPathPainter extends CustomPainter {
  final List<Offset> positions;
  _PremiumPathPainter(this.positions);

  /// Converts a list of points into a smooth Catmull–Rom spline path.
  Path _createSmoothPath(List<Offset> points) {
    Path path = Path();
    if (points.isEmpty) return path;
    // Start at the first point.
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      Offset p0 = i == 0 ? points[0] : points[i - 1];
      Offset p1 = points[i];
      Offset p2 = points[i + 1];
      Offset p3 = (i + 2 < points.length) ? points[i + 2] : points[i + 1];

      // Calculate control points for smooth cubic Bézier using Catmull–Rom algorithm.
      Offset cp1 = p1 + (p2 - p0) / 6;
      Offset cp2 = p2 - (p3 - p1) / 6;

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    // Offset each level position to align with the center of your LevelCircle (approx. +40, +40).
    List<Offset> offsetPositions =
    positions.map((p) => p + const Offset(40, 40)).toList();
    Path path = _createSmoothPath(offsetPositions);

    // Layer 1: Outer Glow.
    final Paint glowPaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Layer 2: Gradient Stroke.
    final Paint gradientPaint = Paint()
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Colors.green, Colors.greenAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Layer 3: Inner White Highlight.
    final Paint highlightPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.8)
      ..strokeCap = StrokeCap.round;

    // Draw the layers in order.
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, gradientPaint);
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(_PremiumPathPainter oldDelegate) => true;
}



// The LevelCircle widget displays the level number in a circular design.
class LevelCircle extends StatelessWidget {
  final Task task;

  const LevelCircle({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // For completed tasks, display a star with the level number overlay.
          task.isCompleted
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
                '${task.level}',
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
                colors: task.isUnlocked
                    ? [Colors.lightGreen.shade400, Colors.green.shade800]
                    : [Colors.grey.shade300, Colors.grey.shade600],
                stops: const [0.3, 1.0],
                center: Alignment.center,
                radius: 0.9,
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
                '${task.level}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (!task.isUnlocked) EcoPulsatingLock(),
        ],
      ),
    );
  }
}


// The FadingBackground widget uses an animation to fade in the background image.
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
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
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
  /// and store in Firestore.
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

                // Replace the previous _verificationRecord check with this conditional:
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
                    : Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white.withOpacity(0.9),
                  child: CheckboxListTile(
                    activeColor: Colors.green[700],
                    title: Text("Mark task as completed", style: TextStyle(color: Colors.grey[800])),
                    value: taskCompleted,
                    onChanged: (value) {
                      if (taskCompleted || isVerifying) return;
                      if (value == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Your progress is under verification please hold tight")),
                        );
                        _verifyAndMarkComplete();
                      }
                    },
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
