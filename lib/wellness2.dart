import 'dart:typed_data' as typed_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'image_result_page.dart';
import 'imageresult.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
class WellnessPage1 extends StatefulWidget {
  @override
  _WellnessPageState createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage1> {
  File? _selectedImage;
  String? _imageDescription;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Show a dialog to let the user choose
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.green[50],
          title: Text(
            "Choose Image Source",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.green[800],
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade200, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.green[700]),
                  title: Text(
                    "Camera",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[900],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                  hoverColor: Colors.green[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                Divider(color: Colors.green[300], thickness: 1),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green[700]),
                  title: Text(
                    "Gallery",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[900],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                  hoverColor: Colors.green[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return; // If user cancels the dialog

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageDescription = null;
        _isLoading = true; // Set loading state
      });

      // Wait for the frame to render the loading indicator
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _fetchImageDescription(_selectedImage!);
      });
    }
  }

  Future<void> _fetchImageDescription(File image) async {
    setState(() => _isLoading = true);

    // Fetch API keys from Firestore
    List<String> apiKeys = await _fetchAPIKeys();
    if (apiKeys.isEmpty) {
      setState(() => _isLoading = false);
      _showUserMessage("No API keys available. Please try again later.");
      return;
    }

    for (String apiKey in apiKeys) {
      bool success = await _sendImageToAPI(image, apiKey);
      if (success) return; // Exit if a successful response is received
    }

    // If all API keys fail
    setState(() => _isLoading = false);
    _showUserMessage("All API keys failed. Please try again later.");
  }

// Function to fetch API keys from Firestore
  Future<List<String>> _fetchAPIKeys() async {
    try {
      print("🔄 Fetching API Keys from Firestore...");
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection("company")
          .doc("verification") // Adjust doc ID if needed
          .get();

      if (doc.exists && doc.data() != null && doc.data()!.containsKey("keys")) {
        List<String> apiKeys = List<String>.from(doc.data()!["keys"]);
        print("✅ API Keys Retrieved: ${apiKeys.length}");
        return apiKeys;
      } else {
        print("❌ API Key array not found in Firestore!");
      }
    } catch (e) {
      print("⚠️ Error fetching API Keys: $e");
    }
    return [];
  }

  Future<bool> _sendImageToAPI(File image, String apiKey) async {
    try {
      // Convert the picked image to bytes and decode it
      typed_data.Uint8List imageBytes = await image.readAsBytes();
      img.Image? pickedImage = img.decodeImage(imageBytes);

      if (pickedImage == null) {
        _showUserMessage("Invalid image format.");
        return false;
      }

      // Fetch user's recycled images from Firestore
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        List<dynamic> recycledImages = userDoc.data()!['recycledImages'] ?? [];

        for (String base64String in recycledImages) {
          typed_data.Uint8List storedBytes = typed_data.Uint8List.fromList(base64Decode(base64String));
          img.Image? storedImage = img.decodeImage(storedBytes);

          if (storedImage != null && _compareImages(pickedImage, storedImage)) {
            _showAlert(context, "No Reusing Please Be ethical");
            return false;
          }
        }
      }

      // Proceed with the API call
      var url = Uri.parse("https://general-detection.p.rapidapi.com/v1/results?algo=algo1");
      var request = http.MultipartRequest("POST", url)
        ..headers["x-rapidapi-host"] = "general-detection.p.rapidapi.com"
        ..headers["x-rapidapi-key"] = apiKey;
      request.files.add(await http.MultipartFile.fromPath("image", image.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        Map<String, int> objectCounts = {};

        if (data["results"] is List && data["results"].isNotEmpty) {
          for (var result in data["results"]) {
            if (result["entities"] is List) {
              for (var entity in result["entities"]) {
                if (entity["objects"] is List) {
                  for (var object in entity["objects"]) {
                    if (object["entities"] is List) {
                      for (var inner in object["entities"]) {
                        if (inner["classes"] is Map) {
                          Map classesMap = inner["classes"];
                          classesMap.forEach((key, value) {
                            objectCounts[key] = (objectCounts[key] ?? 0) + 1;
                          });
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        setState(() {
          _isLoading = false;
          _imageDescription = objectCounts.toString();
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageResultPage1(image: image, descriptionText: objectCounts),
          ),
        );
        return true;
      } else {
        _showUserMessage("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ API Request Error: $e");
      _showUserMessage("An error occurred while processing the image.");
    }
    return false;
  }

// Function to compare two images pixel by pixel
  bool _compareImages(img.Image img1, img.Image img2) {
    if (img1.width != img2.width || img1.height != img2.height) {
      return false;
    }

    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        if (img1.getPixel(x, y) != img2.getPixel(x, y)) {
          return false;
        }
      }
    }
    return true;
  }

  void _showAlert(BuildContext context, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Alert",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 56,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Attention!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // First dismiss the dialog
                      Navigator.of(context).pop();
                      // Then navigate back to the previous page
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent, backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
    );
  }

// Function to show non-blocking message
  void _showUserMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep the same functionality
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa, color: Colors.white),
            SizedBox(width: 8),
            Text("Wellness & Environment",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green[900],
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Stack(
        children: [
          // 1) Lightened background image from local asset
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/ease.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.7),
                    BlendMode.srcOver,
                  ),
                ),
              ),
            ),
          ),

          // 2) Loading overlay if needed
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading GIF
                      Image.asset(
                        'lib/assets/loading.gif',
                        width: 120,
                        height: 120,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Analyzing Image...",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3) Main content (centered card)
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(top: kToolbarHeight + 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      "Choose an Image",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Image Preview Container
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green[900]!.withOpacity(0.5),
                              width: 3),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.green[50],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _selectedImage == null
                            ? Icon(Icons.add_a_photo,
                            size: 80, color: Colors.green[800])
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_selectedImage!,
                              fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Button
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.upload, color: Colors.white),
                      label: Text("Select Image",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding:
                        EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 6,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Display the formatted response object, for example: {"dog": 8}
                    if (_imageDescription != null)
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "🌱 Description: $_imageDescription",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),

                    // Motivational quote
                    SizedBox(height: 10),
                    Text(
                      "“The earth does not belong to us: we belong to the earth.” 🌍",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}