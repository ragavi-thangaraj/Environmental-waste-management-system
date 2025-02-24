import 'package:ease/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      }
    }
    return {};
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/ease.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.2), // Light overlay
                  BlendMode.dstATop,
                ),
              ),
            ),
          ),

          // Content
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error fetching user data'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No user data available'));
              } else {
                final userData = snapshot.data!;
                final lastCompletion = (userData['lastTaskCompletion'] as Timestamp).toDate();
                final streakCount = userData['streakCount'] ?? 0;
                final now = DateTime.now();
                final isStreakActive = now.difference(lastCompletion).inDays <= 1;

                return Column(
                  children: [
                    // App Bar with Logout Button
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: Icon(Icons.logout, color: Colors.redAccent),
                          onPressed: () => _logout(context),
                        ),
                      ],
                    ),

                    // Profile Information
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: NetworkImage(userData['profile'] ?? 'https://via.placeholder.com/150'),
                            ),
                            SizedBox(height: 16),
                            Text(
                              userData['name'] ?? 'No Name',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Phone: ${userData['phone'] ?? 'No Phone'}',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            SizedBox(height: 20),

                            // Stats Cards
                            Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.score, color: Colors.blueAccent),
                                title: Text('Total Score'),
                                trailing: Text(
                                  '${userData['lastTaskScore'] ?? 0}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.calendar_today, color: Colors.green),
                                title: Text('Last Task Completion'),
                                trailing: Text('${lastCompletion.toLocal()}'.split(' ')[0]),
                              ),
                            ),
                            SizedBox(height: 10),
                            Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.whatshot, color: Colors.orangeAccent),
                                title: Text('Current Streak'),
                                trailing: Text(
                                  isStreakActive ? '$streakCount days' : 'No active streak',
                                  style: TextStyle(
                                    color: isStreakActive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
