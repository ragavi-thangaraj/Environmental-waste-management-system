import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
class HelpPage extends StatelessWidget {
  final Map<String, dynamic> nearestOfficer;
  final File image; // File type for user-provided image
  final String text;

  HelpPage({required this.nearestOfficer, required this.image, required this.text});

  // Function to launch the dialer
  // Function to make a direct phone call
  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
    } else {
      print("Invalid phone number");
    }
  }
  // Function to open Google Maps with latitude & longitude from a string format
  void _openGoogleMaps(BuildContext context) async {
    final String? latLong = nearestOfficer['latlong'];

    if (latLong != null && latLong.contains(",")) {
      final List<String> coordinates = latLong.split(",");
      if (coordinates.length == 2) {
        final double latitude = double.tryParse(coordinates[0].trim()) ?? 0.0;
        final double longitude = double.tryParse(coordinates[1].trim()) ?? 0.0;

        if (latitude != 0.0 && longitude != 0.0) {
          final Uri mapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

          if (await canLaunchUrl(mapsUrl)) {
            await launchUrl(mapsUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Could not open Google Maps")),
            );
          }
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid location format")),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background for contrast
      appBar: AppBar(
        title: Text(
          "Help & Nearest Officer",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
              color: Colors.white
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section with Orange Gradient Overlay
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(image), // User-provided image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.orange.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    "Emergency Assistance",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black45)],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Officer Details
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Officer Name
                          Text(
                            nearestOfficer["name"] ?? "Unknown",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                          ),
                          SizedBox(height: 8),

                          // Tamil Name
                          Text(
                            nearestOfficer["tname"] ?? "",
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                          SizedBox(height: 8),

                          // Contact Number (Tappable to Dial)
                          GestureDetector(
                            onTap: () => _makePhoneCall(nearestOfficer["contact"] ?? ""),
                            child: Row(
                              children: [
                                Icon(Icons.phone, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  nearestOfficer["contact"] ?? "Not Available",
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.underline, // To indicate it's tappable
                                    color: Colors.blue, // Highlighting it as a link
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),

                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  nearestOfficer["location"] ?? "Location not available",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Municipal Office Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              nearestOfficer["imageUrl"] ?? "",
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 150, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openGoogleMaps(context),
        backgroundColor: Colors.orange,
        child: Icon(Icons.map, color: Colors.white),
        tooltip: "View Location on Map",
      ),
    );
  }
}
