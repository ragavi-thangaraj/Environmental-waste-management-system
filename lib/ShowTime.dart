import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
class RecyclingSearchPage extends StatefulWidget {
  @override
  _RecyclingSearchPageState createState() => _RecyclingSearchPageState();
}

class _RecyclingSearchPageState extends State<RecyclingSearchPage> {
  String _currentAddress = "Fetching location...";
  double? _latitude, _longitude;
  bool _isLoadingLocation = true;
  bool _isLoadingResults = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Get User's Current Location
  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          setState(() {
            _currentAddress = "Location permission denied";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      Position position =
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;
      List<Placemark>? placemarks =
      await GeocodingPlatform.instance?.placemarkFromCoordinates(_latitude!, _longitude!);
      Placemark? place = placemarks?[0];
      setState(() {
        _currentAddress = '${place!.name}, ${place.locality}, ${place.country}';
        _isLoadingLocation = false;
      });

      _fetchPlaces();
    } catch (e) {
      setState(() {
        _currentAddress = "Location not available";
        _isLoadingLocation = false;
      });
    }
  }

  // Fetch Data from Firestore and Calculate Distance
  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoadingResults = true;
      _results.clear();
    });

    try {
      await Future.wait([
        _fetchCollection('erode'),
        _fetchCollection('perundurai'),
      ]);
    } catch (e) {
      print("Error fetching places: $e");
      setState(() {
        _isLoadingResults = false;
      });
    }
  }

  // Fetch Collection and Process Documents
  Future<void> _fetchCollection(String collectionName) async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection(collectionName).get();
      for (var doc in snapshot.docs) {
        _processDocument(doc);
      }
    } catch (e) {
      print("Error fetching collection $collectionName: $e");
    }
  }

  // Process Document, Calculate Distance, and Add to Results
  void _processDocument(QueryDocumentSnapshot doc) {
    try {
      String latlong = doc['latlong'];
      List<String> latLongParts = latlong.split(',');
      double lat = double.parse(latLongParts[0]);
      double lon = double.parse(latLongParts[1]);

      double distance = _calculateDistance(lat, lon, _latitude!, _longitude!);

      // Avoid duplicates by name
      bool isDuplicate = _results.any((place) => place['name'] == doc['name']);
      if (!isDuplicate) {
        setState(() {
          _results.add({
            'name': doc['name'],
            'address': doc['address'],
            'lat': lat,
            'lon': lon,
            'distance': distance,
            'image': doc['image'],
            'phone': doc['phone'],
            'link': doc['link'],
          });
          _results.sort((a, b) => a['distance'].compareTo(b['distance']));
        });
      }
      _isLoadingResults = false;
    } catch (e) {
      print("Error processing document: $e");
    }
  }

  // Calculate Distance between User and Place
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double piVal = 3.141592653589793238;
    const double radius = 6371; // in km
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  double _degreesToRadians(double degree) {
    return degree * pi / 180.0;
  }

  // Navigate to Details Page
  void _onCardTap(Map<String, dynamic> placeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          placeData: placeData,
          userLatitude: _latitude!,
          userLongitude: _longitude!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use a Stack to place a background image behind the results area
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recycling Centers & Junk Yards",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image covering only the results area
          Positioned(
            top: 200, // Start background image after the top (location) section
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/ease.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              // A gradient to fade from white to transparent:
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.9), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Section
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green.shade700, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Your Location:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _isLoadingLocation
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                  ),
                )
                    : Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      _currentAddress,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Results Section
                // Updated Results Section inside your build() method
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      double distance = result['distance'];
                      String distanceStr = "${distance.toStringAsFixed(1)} km away";
                      return InkWell(
                        onTap: () => _onCardTap(result),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          shadowColor: Colors.green.shade100,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Left: Image with rounded corners
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    child: Image.network(
                                      result['image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Right: Text information
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        result['address'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 16, color: Colors.green.shade600),
                                          SizedBox(width: 4),
                                          Text(
                                            distanceStr,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Optional: an arrow icon to indicate tappable details
                                Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.green.shade600),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class DetailPage extends StatelessWidget {
  final Map<String, dynamic> placeData;
  final double userLatitude;
  final double userLongitude;

  DetailPage({
    required this.placeData,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  Widget build(BuildContext context) {
    // Extract recycling and accessibility data from placeData
    List<String> recyclingList = List<String>.from(placeData['recycling'] ?? []);
    String accessibility = placeData['accessibility'] ?? "N/A";

    // Calculate distance from the user
    double distance = _calculateDistance(
        placeData['lat'], placeData['lon'], userLatitude, userLongitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recycling Center Nearby',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      // Stack to layer the background image with gradient and the content
      body: Stack(
        children: [
          // Background: local asset with a gradient overlay that starts white at the top
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
                      Colors.white.withOpacity(0.6),
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
          // Content Area
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header image with rounded corners and fade overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      Image.network(
                        placeData['image'],
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black54,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Title with modern Google Fonts
                Text(
                  placeData['name'],
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.green.shade800,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Divider(
                  thickness: 1,
                  color: Colors.green.shade100,
                ),
                SizedBox(height: 16),
                // Address Section
                _buildAddressSection(),
                SizedBox(height: 20),
                // Animated Distance Section
                _buildDistanceSection(distance),
                SizedBox(height: 20),
                // Phone Section (call-to-action)
                _buildPhoneSection(),
                SizedBox(height: 20),
                // Accessibility Section with soft frosted glass effect
                _buildAccessibilitySection(accessibility),
                SizedBox(height: 20),
                // Recycling Options Section
                _buildRecyclingOptionsSection(recyclingList),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
      // Floating action button for launching link
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final link = placeData['link'];
          if (await canLaunch(link)) {
            await launch(link);
          } else {
            throw 'Could not launch $link';
          }
        },
        backgroundColor: Colors.green.shade800,
        child: Icon(
          Icons.location_on,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  // Address Section with icon
  Widget _buildAddressSection() {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.green.shade700, size: 30),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            placeData['address'],
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Animated Distance Section with TweenAnimationBuilder
  Widget _buildDistanceSection(double distance) {
    final progressValue = (distance / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Distance from you:",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade800),
        ),
        SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progressValue),
          duration: Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade200, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 12,
                    valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                    backgroundColor: Colors.white.withOpacity(0.3),
                  ),
                ),
                Text(
                  "${distance.toStringAsFixed(2)} km",
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Phone Section with call action wrapped in a Card
  Widget _buildPhoneSection() {
    String phone = placeData['phone'] ?? '';
    return GestureDetector(
      onTap: () async {
        if (phone.isNotEmpty) {
          final callUrl = 'tel:$phone';
          if (await canLaunch(callUrl)) {
            await launch(callUrl);
          } else {
            throw 'Could not launch $callUrl';
          }
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.phone, color: Colors.green.shade700, size: 30),
              SizedBox(width: 10),
              Text(
                "Phone: ${phone.isNotEmpty ? phone : 'N/A'}",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Accessibility Section with frosted glass effect
  Widget _buildAccessibilitySection(String accessibility) {
    return accessibility != "N/A"
        ? ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          padding: EdgeInsets.all(16),
          child: Text(
            "Accessibility: $accessibility",
            style: TextStyle(
                fontSize: 18, color: Colors.green.shade800, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    )
        : SizedBox.shrink();
  }

  // Recycling Options Section with updated sleek cards
  Widget _buildRecyclingOptionsSection(List<String> recyclingList) {
    return recyclingList.isNotEmpty
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recycling Options:",
          style: TextStyle(
              fontSize: 18, color: Colors.green.shade800, fontWeight: FontWeight.bold),
        ),
        ...recyclingList.map((item) => Card(
          color: Colors.green.shade50,
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "- $item",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        )),
      ],
    )
        : SizedBox.shrink();
  }

  // Calculate distance between coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Earth radius in kilometers
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  // Convert degrees to radians
  double _degreesToRadians(double degree) {
    return degree * pi / 180.0;
  }
}


