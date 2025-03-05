import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'login.dart';
import 'package:google_fonts/google_fonts.dart';
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

class OnboardingCarousel extends StatefulWidget {
  final VoidCallback onSkip;

  OnboardingCarousel({required this.onSkip});

  @override
  _OnboardingCarouselState createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  int _currentIndex = 0;
  bool isLoading = false;
  final List<Map<String, String>> slides = [
    {
      'image': 'https://media.istockphoto.com/id/1317323736/photo/a-view-up-into-the-trees-direction-sky.jpg?s=612x612&w=0&k=20&c=i4HYO7xhao7CkGy7Zc_8XSNX_iqG0vAwNsrH1ERmw2Q=',
      'quote': "Your Appearance Reflects Nature's Beauty",
      'subtitle': "Transform Your Style, Embrace a Sustainable Future"
    },
    {
      'image': 'https://storage.googleapis.com/nsn-content/production/media/uploads/whatsapp_image_2022-07-26_at_2.54.32_pm(2).jpeg',
      'quote': "Style is a Reflection of Your Environmental Impact",
      'subtitle': "Step into Eco-Friendly Fashion and Make a Positive Change"
    },
    {
      'image': 'https://img.freepik.com/free-photo/tea-plantation_658691-674.jpg',
      'quote': "Look Good, Feel Earth-Friendly",
      'subtitle': "Discover the Power of Eco-Conscious Fashion Choices"
    },
  ];


  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      await saveUserData(user);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user: user)),
        );
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
    }

    setState(() => isLoading = false); // Hide loading
  }

  Future<void> saveUserData(User? user) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': user.displayName,
        'email': user.email,
        'phone': user.phoneNumber,
        'profile': user.photoURL,
      }, SetOptions(merge: true));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CarouselSlider.builder(
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 5),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOut,
              enableInfiniteScroll: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemCount: slides.length,
            itemBuilder: (context, index, realIndex) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(slides[index]['image']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Adjusted gradient to make top 1/4 transparent, then transition to white
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent, // Transparent for the top 1/4
                          Colors.white.withOpacity(0.0), // Start fading to white
                          Colors.white, // Full white at the bottom
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.25, 1.0], // First 25% transparent, then transition to white
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Text(
                          slides[index]['quote']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.greatVibes(
                            fontSize: 32, // Slightly larger for an elegant feel
                            fontWeight: FontWeight.bold, // Normal weight for cursive look
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          slides[index]['subtitle']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.greatVibes(
                            fontSize: 20,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 30,
                    right: 30,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : signInWithGoogle,
                      icon: Image.network(
                        'https://lh3.googleusercontent.com/COxitqgJr1sJnIDe8-jiKhxDx1FrYbtRHKJ9z_hELisAlapwE9LUPh6fcXIfb5vwpbMl4xl9H9TRFPc5NOO8Sb3VSgIBrfRYvW6cUA',
                        height: 24,
                        width: 24,
                      ),
                      label: isLoading
                          ? CircularProgressIndicator(color: Colors.black)
                          : Text(
                        'Login with Google',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                    ),
                  ),

                ],
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                    (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentIndex ? 30 : 15, // Longer active line
                  height: 6, // Line thickness
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5), // Rounded edges
                    color: index == _currentIndex
                        ? Colors.green // Active line color
                        : Colors.white.withOpacity(0.5), // Inactive line color
                    boxShadow: index == _currentIndex
                        ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                        : [],
                    gradient: index == _currentIndex
                        ? LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null, // Gradient effect for active line
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
