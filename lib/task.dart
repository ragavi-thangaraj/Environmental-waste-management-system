import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'task_games/ocean_cleanup_game.dart';
import 'task_games/recycling_sort_game.dart';
import 'task_games/plant_garden_game.dart';
import 'task_games/energy_saver_game.dart';
import 'task_games/water_conservation_game.dart';
import 'task_games/eco_craft_game.dart';

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late ConfettiController _confettiController;
  
  List<TaskLevel> taskLevels = [];
  int currentUnlockedLevel = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTasks();
    _loadProgress();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _cardController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confettiController = ConfettiController(duration: Duration(seconds: 3));
    
    _cardController.forward();
  }

  void _initializeTasks() {
    taskLevels = [
      TaskLevel(
        id: 1,
        title: "Ocean Hero",
        subtitle: "Save marine life by cleaning the ocean",
        description: "Help sea creatures by removing plastic waste from the ocean. Learn about marine pollution!",
        icon: "🌊",
        color: Colors.blue,
        difficulty: "Easy",
        estimatedTime: "5 min",
        gameWidget: OceanCleanupGame(),
        isUnlocked: true,
      ),
      TaskLevel(
        id: 2,
        title: "Sorting Champion",
        subtitle: "Master the art of waste separation",
        description: "Sort different types of waste into correct bins. Become a recycling expert!",
        icon: "♻️",
        color: Colors.green,
        difficulty: "Easy",
        estimatedTime: "3 min",
        gameWidget: RecyclingSortGame(),
        isUnlocked: false,
      ),
      TaskLevel(
        id: 3,
        title: "Garden Guardian",
        subtitle: "Create your own green paradise",
        description: "Plant seeds, water them, and watch your garden grow. Learn about plant care!",
        icon: "🌱",
        color: Colors.lightGreen,
        difficulty: "Medium",
        estimatedTime: "7 min",
        gameWidget: PlantGardenGame(),
        isUnlocked: false,
      ),
      TaskLevel(
        id: 4,
        title: "Energy Detective",
        subtitle: "Find and fix energy waste",
        description: "Explore a house and turn off wasteful appliances. Save energy, save the planet!",
        icon: "⚡",
        color: Colors.amber,
        difficulty: "Medium",
        estimatedTime: "6 min",
        gameWidget: EnergySaverGame(),
        isUnlocked: false,
      ),
      TaskLevel(
        id: 5,
        title: "Water Wizard",
        subtitle: "Protect our precious water resources",
        description: "Fix leaky pipes and save water drops. Every drop counts!",
        icon: "💧",
        color: Colors.cyan,
        difficulty: "Medium",
        estimatedTime: "5 min",
        gameWidget: WaterConservationGame(),
        isUnlocked: false,
      ),
      TaskLevel(
        id: 6,
        title: "Eco Artist",
        subtitle: "Turn trash into treasure",
        description: "Create beautiful art from recycled materials. Be creative and eco-friendly!",
        icon: "🎨",
        color: Colors.purple,
        difficulty: "Hard",
        estimatedTime: "10 min",
        gameWidget: EcoCraftGame(),
        isUnlocked: false,
      ),
    ];
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString('task_progress');
    if (progressData != null) {
      final Map<String, dynamic> progress = json.decode(progressData);
      setState(() {
        currentUnlockedLevel = progress['unlockedLevel'] ?? 0;
        for (int i = 0; i <= currentUnlockedLevel && i < taskLevels.length; i++) {
          taskLevels[i].isUnlocked = true;
          if (progress['completedTasks'] != null) {
            taskLevels[i].isCompleted = progress['completedTasks'].contains(i + 1);
          }
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completedTasks = taskLevels
        .where((task) => task.isCompleted)
        .map((task) => task.id)
        .toList();
    
    final progressData = {
      'unlockedLevel': currentUnlockedLevel,
      'completedTasks': completedTasks,
    };
    
    await prefs.setString('task_progress', json.encode(progressData));
  }

  void _completeTask(int taskId) {
    setState(() {
      final taskIndex = taskLevels.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        taskLevels[taskIndex].isCompleted = true;
        
        // Unlock next level
        if (taskIndex + 1 < taskLevels.length && currentUnlockedLevel == taskIndex) {
          currentUnlockedLevel = taskIndex + 1;
          taskLevels[taskIndex + 1].isUnlocked = true;
          _confettiController.play();
        }
      }
    });
    _saveProgress();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [Colors.green, Colors.blue, Colors.orange, Colors.pink],
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(child: _buildTaskList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50).withOpacity(0.1),
            Color(0xFF2196F3).withOpacity(0.1),
            Color(0xFFFFEB3B).withOpacity(0.1),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return CustomPaint(
            painter: FloatingElementsPainter(_backgroundController.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.green[800]),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  "🌍 Eco Adventures",
            style: TextStyle(
                    fontSize: 28,
              fontWeight: FontWeight.bold,
                    color: Colors.green[800],
            ),
            textAlign: TextAlign.center,
          ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                  "Level ${currentUnlockedLevel + 1}",
              style: TextStyle(
                color: Colors.white,
                    fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
          SizedBox(height: 10),
          Text(
            "Complete missions to unlock new adventures!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final completedTasks = taskLevels.where((task) => task.isCompleted).length;
    final progress = completedTasks / taskLevels.length;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
                "Progress",
            style: TextStyle(
                  fontSize: 18,
              fontWeight: FontWeight.bold,
                  color: Colors.green[800],
            ),
          ),
          Text(
                "$completedTasks/${taskLevels.length} completed",
            style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: taskLevels.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _cardController,
          builder: (context, child) {
            final delay = index * 0.1;
            final animationValue = Curves.easeOutBack.transform(
              (_cardController.value - delay).clamp(0.0, 1.0),
            );
            final safeOpacity = animationValue.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 50 * (1 - animationValue)),
              child: Opacity(
                opacity: safeOpacity,
                child: _buildTaskCard(taskLevels[index], index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TaskLevel task, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Main Card
          Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
                colors: task.isUnlocked
                    ? [task.color.withOpacity(0.8), task.color]
                    : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
          BoxShadow(
                  color: task.isUnlocked 
                      ? task.color.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
          ),
        ],
      ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: task.isUnlocked ? () => _startTask(task) : null,
                child: Padding(
                  padding: EdgeInsets.all(20),
      child: Row(
        children: [
                      // Task Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
            child: Center(
                          child: Text(
                            task.icon,
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      
                      // Task Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                  style: TextStyle(
                                      fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (task.isCompleted)
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(
                              task.subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                _buildInfoChip(task.difficulty, Icons.star),
                                SizedBox(width: 10),
                                _buildInfoChip(task.estimatedTime, Icons.access_time),
                              ],
              ),
          ],
        ),
      ),
                      
                      // Arrow or Lock
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          task.isUnlocked ? Icons.arrow_forward_ios : Icons.lock,
                    color: Colors.white,
                          size: 20,
                  ),
                ),
              ],
                  ),
                ),
              ),
            ),
          ),
          
          // Unlock Animation
          if (!task.isUnlocked && index == currentUnlockedLevel + 1)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.yellow.withOpacity(0.3),
                      Colors.orange.withOpacity(0.3),
                    ],
                  ),
              ),
              child: Center(
                child: Text(
                    "Complete previous task to unlock!",
                    style: TextStyle(
                    color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                  ),
                ),
              ),
            ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _startTask(TaskLevel task) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TaskGameWrapper(
          task: task,
          onComplete: () => _completeTask(task.id),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }
}

class TaskLevel {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final Color color;
  final String difficulty;
  final String estimatedTime;
  final Widget gameWidget;
  bool isUnlocked;
  bool isCompleted;

  TaskLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.estimatedTime,
    required this.gameWidget,
    this.isUnlocked = false,
    this.isCompleted = false,
  });
}

class TaskGameWrapper extends StatelessWidget {
  final TaskLevel task;
  final VoidCallback onComplete;

  const TaskGameWrapper({
    Key? key,
    required this.task,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget gameWidget = task.gameWidget;
    // Pass onComplete to all supported games
    if (gameWidget is OceanCleanupGame) {
      gameWidget = OceanCleanupGame(onComplete: onComplete);
    } else if (gameWidget is RecyclingSortGame) {
      gameWidget = RecyclingSortGame(onComplete: onComplete);
    } else if (gameWidget is PlantGardenGame) {
      gameWidget = PlantGardenGame(onComplete: onComplete);
    } else if (gameWidget is EnergySaverGame) {
      gameWidget = EnergySaverGame(onComplete: onComplete);
    } else if (gameWidget is WaterConservationGame) {
      gameWidget = WaterConservationGame(onComplete: onComplete);
    } else if (gameWidget is EcoCraftGame) {
      gameWidget = EcoCraftGame(onComplete: onComplete);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        backgroundColor: task.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: gameWidget,
    );
  }
}

class FloatingElementsPainter extends CustomPainter {
  final double animationValue;

  FloatingElementsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green.withOpacity(0.1);
    
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i / 20) + animationValue * 50) % size.width;
      final y = (size.height * ((i * 0.7) % 1) + animationValue * 30) % size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        5 + (i % 3) * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}