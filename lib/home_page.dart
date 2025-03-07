import 'package:ease/profile.dart';
import 'package:ease/task.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wellness_page.dart';
import 'ShowTime.dart';

class HomePage extends StatelessWidget {
  final User user;
  HomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1) Light-themed AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, color: Colors.green[900], size: 28),
            SizedBox(width: 8),
            Text(
              "Our Home",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green[900],
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.green[900]),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.green[900]),
            onPressed: () {
              // Navigate to the profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),


      // 2) Main Body
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          // Loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Error / no data
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "No user data found!",
                style: TextStyle(color: Colors.black87),
              ),
            );
          }

          // Once data is loaded, build the UI with a Stack
          return Stack(
            children: [
              // 3) Background image behind everything
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/ease.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.2),
                        BlendMode.srcOver,
                      ),
                    ),
                  ),
                ),
              ),

              // 4) Foreground: Scrollable content
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A) Top portion: fully white background
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Column(
                        children: [
                          // Top Profile/Logo Section
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(
                              'https://img.myloview.com/plakaty/mother-earth-day-and-world-environment-day-concept-with-hand-holding-earth-planet-700-198028430.jpg',
                            ),
                            onBackgroundImageError: (_, __) =>
                                Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                          SizedBox(height: 16),

                          Text(
                            "Saving Earth, One Step at a Time",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Take a step today towards a greener future 🌿🌍",
                            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // B) Fading container: from white (top) to transparent (bottom)
                    Container(
                      // This gradient will fade out the white to show the background
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      // Some padding on top to space the fade below your text
                      padding: EdgeInsets.only(top: 24, left: 16, right: 16),
                      child: Column(
                        children: [
                          // 5) Grid of cards
                          GridView.count(
                            crossAxisCount: 2, // Exactly 2 cards per row
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.75,
                            children: [
                              _buildCardWithBackground(
                                context,
                                _buildFeatureCard(
                                  context,
                                  Icons.eco,
                                  "Recycle rather than dump!",
                                  "Discover ways to live sustainably.",
                                  Colors.green[100]!,
                                  Colors.green[800]!,
                                ),
                              ),
                              _buildCardWithBackground(
                                context,
                                _buildFeatureCard(
                                  context,
                                  Icons.nature_people,
                                  "Wellness & Environment",
                                  "Stay healthy while saving the planet.",
                                  Colors.orange[100]!,
                                  Colors.orange[800]!,
                                ),
                              ),
                              _buildCardWithBackground(
                                context,
                                _buildFeatureCard(
                                  context,
                                  Icons.track_changes,
                                  "Daily Green Challenge",
                                  "A new challenge every day!",
                                  Colors.blue[100]!,
                                  Colors.blue[800]!,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // (Optional) Wraps a card with its own background (currently minimal)
  Widget _buildCardWithBackground(BuildContext context, Widget card) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage('lib/assets/ease.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.2),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: card,
    );
  }

  // Card UI with a curved accent in the top-right corner
  Widget _buildFeatureCard(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Color bgColor,
      Color iconColor,
      ) {
    // Determine the accent icon based on the title
    IconData accentIcon;
    if (title == "Recycle rather than dump!") {
      accentIcon = Icons.recycling;
    } else if (title == "Wellness & Environment") {
      accentIcon = Icons.spa;
    } else if (title == "Daily Green Challenge") {
      accentIcon = Icons.fitness_center;
    } else {
      accentIcon = icon;
    }

    return GestureDetector(
      onTap: () {
        if (title == "Wellness & Environment") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WellnessPage()),
          );
        } else if (title == "Recycle rather than dump!") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecyclingSearchPage()),
          );
        } else if (title == "Daily Green Challenge") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskPage()),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // Card background
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Curved accent in the top-right corner with the accent icon
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    accentIcon,
                    color: iconColor.withOpacity(0.8),
                    size: 30,
                  ),
                ),
              ),
            ),
            // Card content: Icon, Title & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
