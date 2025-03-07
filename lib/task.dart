import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  int _currentIndex = 0;

  // Example tasks (levels) for your eco-themed app.
  final List<Task> tasks = [
    Task(level: 1, isUnlocked: true),
    Task(level: 2, isUnlocked: false),
    Task(level: 3, isUnlocked: false),
    Task(level: 4, isUnlocked: false),
    Task(level: 5, isUnlocked: false),
    Task(level: 6, isUnlocked: false),
    Task(level: 7, isUnlocked: false),
    Task(level: 8, isUnlocked: false),
    Task(level: 9, isUnlocked: false),
    Task(level: 10, isUnlocked: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: FadingBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Center(
                    child: ListWheelScrollView.useDelegate(
                      controller: FixedExtentScrollController(initialItem: 0),
                      physics: FixedExtentScrollPhysics(),
                      itemExtent: 120,
                      perspective: 0.003,
                      diameterRatio: 2.0,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index >= tasks.length) return null;
                          Task task = tasks[index];
                          return GestureDetector(
                            onTap: () => _onLevelSelected(task.level),
                            child: LevelCircle(task: task),
                          );
                        },
                        childCount: tasks.length,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Selected Level: ${tasks[_currentIndex].level}",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handles level selection with a Future call
  Future<void> _onLevelSelected(int level) async {
    Task selectedTask = tasks.firstWhere((task) => task.level == level);

    if (!selectedTask.isUnlocked) {
      // Show a dialog if the level is locked
      _showLockedLevelDialog();
      return;
    }

    // Simulating API call or async task
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(Duration(seconds: 2)); // Simulated API call

    Navigator.pop(context); // Remove loading dialog

    // Navigate based on the level
    if (level == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NeighborhoodLitterPatrolScreen()),
      );
    } else {
      // Add future level navigations here
      print("Level $level selected - Future implementation pending.");
    }
  }

  void _showLockedLevelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Level Locked"),
        content: Text("Complete previous levels to unlock this one."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade900],
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

class Task {
  final int level;
  final bool isUnlocked;

  Task({required this.level, required this.isUnlocked});
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: task.isUnlocked
                    ? [Colors.lightGreen.shade300, Colors.green.shade700]
                    : [Colors.grey.shade400, Colors.grey.shade700],
                center: const Alignment(-0.2, -0.2),
                radius: 0.8,
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

// A pulsating lock widget for locked levels.
class EcoPulsatingLock extends StatefulWidget {
  @override
  _EcoPulsatingLockState createState() => _EcoPulsatingLockState();
}

class _EcoPulsatingLockState extends State<EcoPulsatingLock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.4),
        ),
        child: const Center(
          child: Icon(
            Icons.lock,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
class NeighborhoodLitterPatrolScreen extends StatefulWidget {
  @override
  _NeighborhoodLitterPatrolScreenState createState() =>
      _NeighborhoodLitterPatrolScreenState();
}

class _NeighborhoodLitterPatrolScreenState
    extends State<NeighborhoodLitterPatrolScreen> {
  File? beforePhoto;
  File? afterPhoto;
  bool taskCompleted = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _capturePhoto(bool isBefore) async {
    final XFile? photo =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) {
      setState(() {
        if (isBefore) {
          beforePhoto = File(photo.path);
        } else {
          afterPhoto = File(photo.path);
        }
      });
    }
  }

  Widget _buildPhotoSection(String label, File? photo, bool isBefore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        photo != null
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
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _capturePhoto(isBefore),
          child: Text(isBefore ? 'Capture Before Photo' : 'Capture After Photo'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Neighborhood Litter Patrol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Task description
            Text(
              "Task: Take 10–15 minutes for a quick walk around your neighborhood to pick up litter from sidewalks, parks, or near local shops.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            // Verification instructions
            Text(
              "Verification: Snap before-and-after photos and log your activity using a mobile tracking app or a simple checklist.",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            Divider(height: 32, thickness: 1),
            // Before photo section
            _buildPhotoSection("Before Photo", beforePhoto, true),
            SizedBox(height: 16),
            // After photo section
            _buildPhotoSection("After Photo", afterPhoto, false),
            SizedBox(height: 16),
            // Checklist for task completion
            CheckboxListTile(
              title: Text("Mark task as completed"),
              value: taskCompleted,
              onChanged: (value) {
                setState(() {
                  taskCompleted = value ?? false;
                });
              },
            ),
            SizedBox(height: 16),
            // Display task status
            taskCompleted
                ? Text("Great job! You have completed the task.",
                style: TextStyle(color: Colors.green, fontSize: 16))
                : Container(),
          ],
        ),
      ),
    );
  }
}
