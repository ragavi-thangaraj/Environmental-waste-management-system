import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wellness_page.dart'; // Import the Wellness Page
import 'ShowTime.dart';
class HomePage extends StatelessWidget {
  final User user;
  HomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text("Our Home", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green[900],
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1562683407-043a7eafceb6?q=80&w=2080&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4), // Soft dark overlay for readability
            ),
          ),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text("No user data found!", style: TextStyle(color: Colors.white)));
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 100),
                    // Circular Profile Image
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green[700]!, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage(
                          'https://img.myloview.com/plakaty/mother-earth-day-and-world-environment-day-concept-with-hand-holding-earth-planet-700-198028430.jpg',
                        ),
                        onBackgroundImageError: (_, __) => Icon(Icons.image, size: 70, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Saving Earth, One Step at a Time",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Take a step today towards a greener future 🌿🌍",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    // Eco-Friendly Features
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildFeatureCard(context, Icons.eco, "Recycle rather than dump!", "Discover ways to live sustainably."),
                          _buildFeatureCard(context, Icons.nature_people, "Wellness & Environment", "Stay healthy while saving the planet."),
                          _buildFeatureCard(context, Icons.track_changes, "Daily Green Challenge", "A new challenge every day!"),
                        ],
                      ),
                    ),
                    SizedBox(height: 90),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ Pass `BuildContext` as a parameter
  Widget _buildFeatureCard(BuildContext context, IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        // Handle tap for navigation
        if (title == "Wellness & Environment") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => WellnessPage()));
        } else if (title == "Recycle rather than dump!") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => RecyclingSearchPage())); // Replace with actual page
        } else if (title == "Daily Green Challenge") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => WellnessPage())); // Replace with actual page
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[100],
            ),
            child: Icon(icon, color: Colors.green[800], size: 28),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.black54, fontSize: 12)),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.green[700]),
        ),
      ),
    );
  }
}
