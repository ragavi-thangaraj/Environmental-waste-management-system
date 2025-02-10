import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ease Earth 🏃‍➡️🏃',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? isFirstTime = true;

  @override
  void initState() {
    super.initState();
    checkFirstTimeUser();
  }

  void checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool firstTime = prefs.getBool('first_time') ?? true;

    print("First-time user: $firstTime"); // Debugging

    if (firstTime) {
      await prefs.setBool('first_time', false);
    }

    setState(() {
      isFirstTime = firstTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstTime == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (isFirstTime == true) {
      return OnboardingCarousel(
        onSkip: () {
          setState(() {
            isFirstTime = false;
          });
        },
      );
    }
    return UserHomePage();
  }
}

class OnboardingCarousel extends StatelessWidget {
  final VoidCallback onSkip;

  OnboardingCarousel({required this.onSkip});

  final List<Map<String, String>> slides = [
    {
      'image': 'https://images.aiscribbles.com/c9ed99ddf71e4ddea8c75d54ac371726.jpg?v=f428f2',
      'quote': "“Breathe in nature, breathe out stress.”",
    },
    {
      'image': 'https://storage.googleapis.com/nsn-content/production/media/uploads/whatsapp_image_2022-07-26_at_2.54.32_pm(2).jpeg',
      'quote': "“Every sunrise is an invitation to grow.”",
    },
    {
      'image': 'https://img.freepik.com/free-photo/tea-plantation_658691-674.jpg',
      'quote': "“Find peace where the wild things are.”",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carousel Slider with animations
          CarouselSlider.builder(
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 5),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOut,
              enableInfiniteScroll: true,
              enlargeCenterPage: true,
            ),
            itemCount: slides.length,
            itemBuilder: (context, index, realIndex) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(slides[index]['image']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient Overlay for better contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Quote Text with fade-in animation
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 800),
                          child: Text(
                            slides[index]['quote']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                              shadows: [
                                Shadow(
                                  blurRadius: 8.0,
                                  color: Colors.black38,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Skip Button - Styled for better UX
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: onSkip,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // Dots Indicator
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                    (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class UserHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return LoginApp();
          }
          return HomePage(user: user);
        },
      );
    } else {
      return LoginApp();
    }
  }
}
