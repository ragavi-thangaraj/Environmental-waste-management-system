import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'help.dart';
class DisposalPage extends StatefulWidget {
  final String responseText;
  final File image;
  DisposalPage({required this.responseText,required this.image});

  @override
  _DisposalPageState createState() => _DisposalPageState();
}

class _DisposalPageState extends State<DisposalPage> {
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  bool showTasks = false;
  late String description;
  late List<String> tasks;
  Map<String, bool> completedTasks = {};
  int totalScore = 0;
  int visibleLines = 4;
  late List<String> youtubeLinks;
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    Map<String, dynamic> extractedData = extractDescriptionAndTasks(widget.responseText);
    description = extractedData["description"];
    youtubeLinks = extractYouTubeLinks(description);

    tasks = extractedData["tasks"];

    for (var task in tasks) {
      completedTasks[task] = false;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  void showMore() {
    setState(() {
      visibleLines += 4; // Increase the number of lines displayed
    });
  }
  void toggleTasks() {
    setState(() {
      showTasks = !showTasks;
    });
  }

  List<String> extractYouTubeLinks(String text) {
    // Define a map of keywords to lists of YouTube video URLs.
    Map<String, List<String>> keywordVideos = {
      'aluminum': [
        'https://www.youtube.com/shorts/4ZVpC1nfmzE',
        'https://www.youtube.com/watch?v=_ItLfaO_WY0&pp=ygUcY3JhZnQgd29ya3Mgb24gYWx1bWluaXVtIGNhbg%3D%3D',
        'https://www.youtube.com/watch?v=5XAFMEBiouQ&pp=ygUcY3JhZnQgd29ya3Mgb24gYWx1bWluaXVtIGNhbg%3D%3D',
      ],
      'paper': [
        'https://www.youtube.com/shorts/rOQpYiU8y1M',
        'https://www.youtube.com/shorts/rWF0YPzxwb8',
        'https://www.youtube.com/shorts/7uYcSRMb5xE',
        'https://www.youtube.com/watch?v=aaz4Qe6zYyU&pp=ygUZY3JhZnQgd29yayBvbiB3YXN0ZSBwYXBlcg%3D%3D',
      ],
      // Add more keyword mappings here if needed
    };

    // List to hold the results.
    List<String> resultLinks = [];

    // Check if the text contains any of the keywords and add the corresponding videos.
    keywordVideos.forEach((keyword, links) {
      if (text.toLowerCase().contains(keyword.toLowerCase())) {
        resultLinks.addAll(links);
      }
    });

    return resultLinks;
  }

  Future<Map<String, dynamic>?> _findNearestMunicipalOfficer(Position userPosition) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> allOffices = [];

    // List of documents to fetch data from
    List<String> documents = ["erode", "perundurai"];

    for (String doc in documents) {
      DocumentSnapshot snapshot = await firestore.collection("municipal_office").doc(doc).get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey("municipal")) {
          List<dynamic> municipalList = data["municipal"];

          for (var office in municipalList) {
            allOffices.add(office as Map<String, dynamic>);
          }
        }
      }
    }

    // Find the nearest office
    double minDistance = double.infinity;
    Map<String, dynamic>? nearestOffice;

    for (var office in allOffices) {
      List<String> latLong = (office['latlong'] as String).split(',');
      double officeLat = double.parse(latLong[0]);
      double officeLong = double.parse(latLong[1]);

      double distance = _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        officeLat,
        officeLong,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestOffice = office;
      }
    }

    return nearestOffice;
  }
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Radius of the Earth in km
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
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
      if (completedTasks[task]!) {
        // If task is already completed, deselect it and subtract points
        completedTasks[task] = false;
        totalScore -= calculatePoints(task);
      } else {
        // If task is not completed, mark it as complete and add points
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

  Future<Position> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error("Location permissions are permanently denied.");
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
      body: Stack(
        children: [
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
          Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.leaf, color: Colors.green[800], size: 28),
                      SizedBox(width: 10),
                      Text("Why is this Important?",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Description with dynamic "Read More"
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textSpan = TextSpan(
                        text: description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      );
                      final textPainter = TextPainter(
                        text: textSpan,
                        maxLines: visibleLines,
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: constraints.maxWidth);

                      final isOverflowing = textPainter.didExceedMaxLines;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            maxLines: visibleLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isOverflowing) // Show Read More button if text is overflowing
                            TextButton(
                              onPressed: showMore,
                              child: Text(
                                "Read More",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 20),

                  if (youtubeLinks.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and icon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.youtube, color: Colors.red, size: 28),
                              const SizedBox(width: 10),
                              Text(
                                "Watch and Learn",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Updated video container with glassmorphic effect
                        Container(
                          height: 280,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Stack(
                                children: [
                                  // Video carousel using PageView.builder
                                  PageView.builder(
                                    controller: _pageController,
                                    itemCount: youtubeLinks.length,
                                    itemBuilder: (context, index) {
                                      String videoId = YoutubePlayer.convertUrlToId(youtubeLinks[index])!;
                                      return Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: YoutubePlayer(
                                            controller: YoutubePlayerController(
                                              initialVideoId: videoId,
                                              flags: const YoutubePlayerFlags(
                                                autoPlay: false,
                                                mute: false,
                                              ),
                                            ),
                                            showVideoProgressIndicator: true,
                                            progressIndicatorColor: Colors.red,
                                          ),
                                        ),
                                      );
                                    },
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                  ),
                                  // Animated page indicator at the bottom
                                  Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(youtubeLinks.length, (index) {
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          width: _currentPage == index ? 12 : 8,
                                          height: _currentPage == index ? 12 : 8,
                                          decoration: BoxDecoration(
                                            color: _currentPage == index ? Colors.redAccent : Colors.white54,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  // Header overlay with a title
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.6),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          topRight: Radius.circular(24),
                                        ),
                                      ),
                                      child: const Text(
                                        "Featured Videos",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Animated page indicators
                      ],
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          toggleTasks(); // This should show the tasks section
                          Future.delayed(Duration(milliseconds: 300), () {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        icon: Icon(Icons.cleaning_services, size: 24),
                        label: Text("Clean", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Position userPosition = await _getUserLocation();
                          Map<String, dynamic>? nearestOfficer = await _findNearestMunicipalOfficer(userPosition);

                          if (nearestOfficer != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HelpPage(nearestOfficer: nearestOfficer,image:widget.image,text:description),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        icon: Icon(Icons.help_outline, size: 24),
                        label: Text("Help", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Show tasks only if "Clean" is pressed
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: showTasks
                        ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(FontAwesomeIcons.tasks, color: Colors.green[800], size: 28),
                            SizedBox(width: 10),
                            Text(
                              "Tasks to Complete",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
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
                                    color: completedTasks[task]!
                                        ? Colors.greenAccent.withOpacity(0.7)
                                        : Colors.white.withOpacity(0.85),
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
                                      completedTasks[task]!
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: Colors.green[800],
                                      size: 26,
                                    ),
                                    title: Text(
                                      task,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[900]
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20,),
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
                    )
                        : SizedBox.shrink(),
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