import 'package:ease/home_page.dart';
import 'package:ease/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Profile Page with improved UI and no profile photo edit
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      }
    }
    return {};
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  // Navigate to the Edit Profile page
  void _editProfile(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userData: userData),
      ),
    ).then((_) {
      // Refresh data after returning from the edit page.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a layered Stack to create a rich background
      body: FutureBuilder<Map<String, dynamic>>(
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
            final name = userData['name'] ?? 'No Name';
            final phone = userData['phone'] ?? 'No Phone';
            final profileUrl = userData['profile'] ??
                'https://via.placeholder.com/150'; // Fallback profile URL

            // Additional stats (if any)
            final totalScore = userData['totalScore'] ?? 0;
            final lastCompletion = userData['lastTaskCompletion'] != null
                ? (userData['lastTaskCompletion'] as Timestamp).toDate()
                : DateTime.now();
            final streakCount = userData['streakCount'] ?? 0;
            final now = DateTime.now();
            final isStreakActive = now.difference(lastCompletion).inDays <= 1;

            return Stack(
              children: [
                // Background Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade700,
                        Colors.green.shade400,
                        Colors.green.shade200,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // Header with title and logout button
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Profile",
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            IconButton(
                              icon: Icon(Icons.logout, color: Colors.white),
                              onPressed: _logout,
                            ),
                          ],
                        ),
                      ),
                      // Layered container for profile details
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(top: 10),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, -3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Profile picture without an edit overlay
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(profileUrl),
                                ),
                                SizedBox(height: 20),
                                // User name and phone details
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Phone: $phone',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Edit Profile button
                                ElevatedButton.icon(
                                  onPressed: () => _editProfile(userData),
                                  icon: Icon(Icons.edit),
                                  label: Text("Edit Profile"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 30),
                                // Stats Cards (read-only)
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    leading:
                                    Icon(Icons.score, color: Colors.blueAccent),
                                    title: Text('Total Score'),
                                    trailing: Text(
                                      '$totalScore',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    leading: Icon(Icons.calendar_today,
                                        color: Colors.green),
                                    title: Text('Last Task Completion'),
                                    trailing: Text(
                                      '${lastCompletion.toLocal()}'.split(' ')[0],
                                    ),
                                  ),
                                ),
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    leading: Icon(Icons.whatshot,
                                        color: Colors.orangeAccent),
                                    title: Text('Current Streak'),
                                    trailing: Text(
                                      isStreakActive
                                          ? '$streakCount days'
                                          : 'No active streak',
                                      style: TextStyle(
                                        color: isStreakActive
                                            ? Colors.green
                                            : Colors.red,
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
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

// Edit Profile Page allowing the user to update their details (excluding profile photo)
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _name = widget.userData['name'] ?? '';
    _phone = widget.userData['phone'] ?? '';
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.update({
          'name': _name,
          'phone': _phone,
        });
        // After successful save, redirect to Homepage (MyApp)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage(user: user)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name Field
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _name = value!,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter your name" : null,
              ),
              SizedBox(height: 20),
              // Phone Field
              TextFormField(
                initialValue: _phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _phone = value!,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter your phone number" : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text("Save Changes",style:TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                  textStyle:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
