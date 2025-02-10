import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wellness_page.dart'; // Import the Wellness Page
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
            Icon(Icons.home, color: Colors.white), // White house icon
            SizedBox(width: 8), // Spacing between icon and text
            Text("Our Home", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green[900],
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Stack(
        children: [
          // Full-Screen Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1562683407-043a7eafceb6?q=80&w=2080&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.1), // Adjust transparency as needed
            ),
          ),
          Container(
            color: Colors.green.withOpacity(0.1), // Adds slight tint for readability
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
                    SizedBox(height: 100), // Adjust for app bar height
                    // Circular Profile Image
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green[700]!, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Take a step today towards a greener future 🌿🌍",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    // Eco-Friendly Features
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildFeatureCard(context, Icons.eco, "Eco-Friendly Tips", "Discover simple ways to live sustainably."),
                          _buildFeatureCard(context, Icons.nature_people, "Wellness & Environment", "Stay healthy while saving the planet."),
                          _buildFeatureCard(context, Icons.track_changes, "Daily Green Challenge", "A new challenge every day!"),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
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
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.85), // Slight transparency
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green[100],
          ),
          child: Icon(icon, color: Colors.green[800], size: 30),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.black54, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.green[700]),
        onTap: () {
          if (title == "Wellness & Environment") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WellnessPage()),
            );
          }
          if (title == "Eco-Friendly Tips") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WellnessPage()),
            );
          }
          if (title == "Daily Green Challenge") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WellnessPage()),
            );
          }
        },
      ),
    );
  }
}

