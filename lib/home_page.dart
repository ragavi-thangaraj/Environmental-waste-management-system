import 'package:ease/localization/app_localizations.dart';
import 'package:ease/profile.dart';
import 'package:ease/task.dart';
import 'package:ease/wellness2.dart';
import 'package:ease/widgets/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wellness_page.dart';
import 'ShowTime.dart';
import 'report.dart';
class HomePage extends StatelessWidget {
  final User user;
  HomePage({required this.user});

  // Method to show the language selection dialog.
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: _buildLanguageDialogContent(context),
        );
      },
    );
  }

  Widget _buildLanguageDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "Select Your Language",
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 16.0),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          ListTile(
            leading:
            const Icon(Icons.sort_by_alpha_sharp, color: Colors.green),
            title: const Text("English"),
            onTap: () {
              _updateLanguage("English");
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.green),
            title: const Text("தமிழ்"),
            onTap: () {
              _updateLanguage("Tamil");
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.translate, color: Colors.green),
            title: const Text("हिन्दी"),
            onTap: () {
              _updateLanguage("Hindi");
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Method to update the language in the 'users' collection.
  void _updateLanguage(String language) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'language': language});
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      // AppBar remains unchanged.
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.translate, color: Colors.green[900]),
          onPressed: () => _showLanguageDialog(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text(
                "Our Home",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.green,
                ),
              );
            }
            final userData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            String language = userData['language'] ?? "English";
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, color: Colors.green[900], size: 28),
                const SizedBox(width: 8),
                Text(
                  localizations.home,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green[900],
                  ),
                ),
              ],
            );
          },
        ),
        iconTheme: IconThemeData(color: Colors.green[900]),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.green[900]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      // Main body content.
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                "No user data found!",
                style: TextStyle(color: Colors.black87),
              ),
            );
          }
          final userData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String language = userData['language'] ?? "English";
          return AnimatedBackground(
            colors: [
              Colors.green.shade100,
              Colors.blue.shade50,
              Colors.yellow.shade50,
              Colors.white,
            ],
            child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        children: [
                          PulsingWidget(
                            child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage:
                            AssetImage('lib/assets/earth.jpg'),
                            onBackgroundImageError: (_, __) => const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.savingEarth,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.subtext,
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.only(
                          top: 24, left: 16, right: 16),
                      child: Column(
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.75,
                            children: [
                              SlideInAnimation(
                                delay: Duration(milliseconds: 200),
                                child: _buildCardWithBackground(
                                context,
                                _buildFeatureCard(
                                  context,
                                  Icons.eco,
                                  "recycle",
                                  localizations.recycleTitle,
                                  localizations.recycleSubtitle,
                                  Colors.green[100]!,
                                  Colors.green[800]!,
                                  language,
                                ),
                                ),
                              ),
                              SlideInAnimation(
                                delay: Duration(milliseconds: 400),
                                child: _buildCardWithBackground(
                                context,
                                _buildFeatureCard(
                                  context,
                                  Icons.track_changes,
                                  "daily",
                                  localizations.dailyChallengeTitle,
                                  localizations.dailyChallengeSubtitle,
                                  Colors.blue[100]!,
                                  Colors.blue[800]!,
                                  language,
                                ),
                                ),
                              ),
                              SlideInAnimation(
                                delay: Duration(milliseconds: 600),
                                child: _buildCardWithBackground(
                                context,
                                _buildFeatureCard(
                                  context,
                                  Icons.track_changes,
                                  "wellness2",
                                  localizations.wellnessTitle,
                                  localizations.wellnessSubtitle,
                                  Colors.green[100]!,
                                  Colors.blue[800]!,
                                  language,
                                ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          );
        },
      ),
      // Bottom taskbar with three evenly spaced buttons.
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.green[900]),
              onPressed: () {

              },
            ),
            IconButton(
              icon: Icon(Icons.request_page_outlined, color: Colors.green[900]),
              onPressed: () {

              },
            ),
            IconButton(
              icon: Icon(Icons.incomplete_circle, color: Colors.green[900]),
              onPressed: () async {
                // Get the current logged in user's id.
                final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

                // Query the reports collection with the filter conditions.
                final QuerySnapshot snapshot = await FirebaseFirestore.instance
                    .collection('reports')
                    .where('userId', isEqualTo: currentUserId)
                    .where('status', isEqualTo: 'Not Approved')
                    .get();

                if (snapshot.docs.isEmpty) {
                  // Display a friendly message if no pending reports are found.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("You have no pending reports."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // If there are pending reports, navigate to MyReportsScreen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyReportsScreen(userId: currentUserId),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }


  // Helper method to wrap a card with its own background.
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

  // Updated feature card widget with an extra identifier parameter.
  Widget _buildFeatureCard(
      BuildContext context,
      IconData icon,
      String cardIdentifier,
      String title,
      String subtitle,
      Color bgColor,
      Color iconColor,
      String language, // New parameter for language
      ) {
    // Choose accent icon based on identifier.
    IconData accentIcon;
    switch (cardIdentifier) {
      case "recycle":
        accentIcon = Icons.autorenew;
        break;
      case "wellness":
        accentIcon = Icons.spa;
        break;
      case "daily":
        accentIcon = Icons.fitness_center;
        break;
      default:
        accentIcon = icon;
    }

    // Adjust font sizes for Tamil.
    double titleFontSize = language == "Tamil" ? 14 : 16;
    double subtitleFontSize = language == "Tamil" ? 11 : 13;

    return GestureDetector(
      onTap: () {
        if (cardIdentifier == "wellness") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WellnessPage()),
          );
        } else if (cardIdentifier == "recycle") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecyclingSearchPage()),
          );
        } else if (cardIdentifier == "daily") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskPage()),
          );
        }
        else if (cardIdentifier == "wellness2") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WellnessPage1()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // Card background
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Curved accent in the top-right corner.
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
            // Card content.
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
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
