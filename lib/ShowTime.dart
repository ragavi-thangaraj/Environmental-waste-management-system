import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;
      List<Placemark>? placemarks = await GeocodingPlatform.instance?.placemarkFromCoordinates(_latitude!, _longitude!);
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
      // Fetch data from both collections concurrently using Future.wait
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
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
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

      // Check if the place already exists in _results based on 'name'
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
          _results.sort((a, b) => a['distance'].compareTo(b['distance'])); // Sort by distance
        });
      }
      _isLoadingResults = false;
    } catch (e) {
      print("Error processing document: $e");
    }
  }

  // Calculate Distance between User and Place
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double pi = 3.141592653589793238;
    const double radius = 6371; // Earth radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c; // Distance in kilometers
  }

  // Convert Degrees to Radians
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recycling Centers & Junk Yards",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24, // Adjusted size for better visibility
          ),
        ),
        backgroundColor: Colors.green.shade800,
        elevation: 0, // No shadow for a cleaner look
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Section with Icon and better styling
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade700, size: 30), // Location Icon
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

            // Results Section with better state handling
            _isLoadingResults
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
              ),
            )
                : _results.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => _onCardTap(_results[index]),
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 6), // Reduced margin
                      elevation: 8, // Slightly reduced elevation for a lighter look
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Rounded corners
                      ),
                      shadowColor: Colors.green.shade200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade100, Colors.green.shade300],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Reduced padding
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(_results[index]['image']),
                              radius: 24, // Reduced avatar size
                              backgroundColor: Colors.transparent,
                            ),
                            title: Text(
                              _results[index]['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Slightly smaller title
                                color: Colors.green.shade800,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  _results[index]['address'],
                                  style: TextStyle(
                                    fontSize: 14, // Smaller subtitle text
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
                : Center(
              child: Text(
                "No results found",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 18, // Slightly larger for better visibility
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DetailPage extends StatelessWidget {
  final Map<String, dynamic> placeData;
  final double userLatitude;
  final double userLongitude;

  DetailPage({required this.placeData, required this.userLatitude, required this.userLongitude});

  @override
  Widget build(BuildContext context) {
    // Extract recycling and accessibility data from placeData
    List<String> recyclingList = List<String>.from(placeData['recycling'] ?? []);
    String accessibility = placeData['accessibility'] ?? "N/A";

    // Calculate distance from the user
    double distance = _calculateDistance(placeData['lat'], placeData['lon'], userLatitude, userLongitude);

    return Scaffold(
      appBar: AppBar(
        title: Text('Recycling Center Nearby',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 24),),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header image
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
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  placeData['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.green.shade800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 10),
                // Address section with icon
                _buildAddressSection(),
                SizedBox(height: 20),
                // Dynamic Distance Meter with smooth animation
                _buildDistanceSection(distance),
                SizedBox(height: 20),
                // Phone number with cool interaction
                _buildPhoneSection(),
                SizedBox(height: 20),
                // Accessibility Info with Glassmorphism effect
                _buildAccessibilitySection(accessibility),
                SizedBox(height: 20),
                // Recycling options in a sleek list
                _buildRecyclingOptionsSection(recyclingList),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await canLaunch(placeData['link'])) {
            await launch(placeData['link']);
          } else {
            throw 'Could not launch ${placeData['link']}';
          }
        },
        backgroundColor: Colors.green.shade800,
        child: Icon(Icons.location_on, size: 30,color: Colors.white,),
      ),
    );
  }

  // Address section with icon
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

  // Distance Section with Animation & Progress Indicator
  Widget _buildDistanceSection(double distance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Distance from you:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800]),
        ),
        SizedBox(height: 8),
        Stack(
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
                value: distance / 100, // Scale the value to a maximum of 100 km
                strokeWidth: 12,
                valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
              ),
            ),
            Positioned(
              child: Text(
                "${distance.toStringAsFixed(2)} km",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Phone section with tap action
  Widget _buildPhoneSection() {
    return GestureDetector(
      onTap: () {
        // Action to dial the phone number (for example)
        String phone = placeData['phone'] ?? '';
        if (phone.isNotEmpty) {
          launch('tel:$phone');
        }
      },
      child: Row(
        children: [
          Icon(Icons.phone, color: Colors.green.shade700, size: 30),
          SizedBox(width: 10),
          Text(
            "Phone: ${placeData['phone'] ?? 'N/A'}",
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // Accessibility Section with Glassmorphism Effect
  Widget _buildAccessibilitySection(String accessibility) {
    return accessibility != "N/A"
        ? Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Text(
        "Accessibility: $accessibility",
        style: TextStyle(fontSize: 18, color: Colors.green[800], fontWeight: FontWeight.bold),
      ),
    )
        : SizedBox.shrink();
  }

  // Recycling Options Section with sleek cards
  Widget _buildRecyclingOptionsSection(List<String> recyclingList) {
    return recyclingList.isNotEmpty
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recycling Options:",
          style: TextStyle(fontSize: 18, color: Colors.green[800], fontWeight: FontWeight.bold),
        ),
        ...recyclingList.map((item) => Card(
          color: Colors.green.shade50,
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Function to calculate distance between two geographic coordinates using the Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double pi = 3.141592653589793238;
    const double radius = 6371; // Earth radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c; // Distance in kilometers
  }

  // Convert Degrees to Radians
  double _degreesToRadians(double degree) {
    return degree * pi / 180.0;
  }
}


