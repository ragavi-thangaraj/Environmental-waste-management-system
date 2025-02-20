import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'image_result_page.dart';
class WellnessPage extends StatefulWidget {
  @override
  _WellnessPageState createState() => _WellnessPageState();
}
class _WellnessPageState extends State<WellnessPage> {
  File? _selectedImage;
  String? _imageDescription;
  bool _isLoading = false;
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageDescription = null;
        _isLoading = true;
      });
      await _fetchImageDescription(_selectedImage!);
    }
  }
  Future<String?> _fetchAPIKey() async {
    try {
      print("🔄 Fetching API Keys from Firestore...");

      // Fetch API keys from Firestore
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection("company")
          .doc("G1HhRecZtrfP72rxEdTI") // Adjust document ID if needed
          .get();

      if (doc.exists && doc.data() != null && doc.data()!.containsKey("api")) {
        List<String> apiKeys = List<String>.from(doc.data()!["api"]); // 🔹 Convert to List<String>

        if (apiKeys.isEmpty) {
          print("❌ No API keys available in Firestore.");
          return null;
        }

        for (String key in apiKeys) {
          print("🔍 Testing API Key: $key");

          bool success = await _testAPIKey(key);
          if (success) {
            print("✅ Found a working API Key: $key");
            return key; // ✅ Return the first valid key
          }
        }

        print("❌ No valid API keys found!");
        return null;
      } else {
        print("❌ API Key array not found in Firestore!");
      }
    } catch (e) {
      print("⚠️ Error fetching API Key: $e");
    }

    return null; // Return null if all keys fail
  }

  Future<bool> _testAPIKey(String apiKey) async {
    try {
      var url = Uri.parse("https://label-image.p.rapidapi.com/detect-label");
      var response = await http.post(url, headers: {
        "X-RapidAPI-Key": apiKey,
        "Content-Type": "application/json"
      });

      print("🔍 Response for $apiKey: ${response.statusCode}");

      return response.statusCode == 200; // ✅ Return true if valid
    } catch (e) {
      print("⚠️ Error testing API Key: $e");
    }
    return false; // ❌ Return false if failed
  }

  Future<void> _fetchImageDescription(File image) async {
    setState(() {
      _isLoading = true;
    });

    String? apiKey = await _fetchAPIKey();

    if (apiKey == null) {
      setState(() {
        _isLoading = false;
      });
      _showUserMessage("This may take a while. Please try again later.");
      return;
    }

    var url = Uri.parse("https://label-image.p.rapidapi.com/detect-label");

    var request = http.MultipartRequest("POST", url)
      ..headers["X-RapidAPI-Key"] = apiKey
      ..files.add(await http.MultipartFile.fromPath("image", image.path));

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("API Response: $responseBody");
        var data = jsonDecode(responseBody);
        List<dynamic> labelsList = data["body"]["labels"];
        List<String> extractedLabels =
        labelsList.map((label) => label["description"].toString()).toList();

        Map<String, dynamic> formattedApiResponse = {
          "body": {
            "labels": extractedLabels
          }
        };

        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ImageResultPage(image: image, descriptionText: formattedApiResponse),
          ),
        );
      } else {
        throw Exception("API Request failed.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showUserMessage("This may take a while. Please try again later.");
      print("Error: $e");
    }
  }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa, color: Colors.white),
            SizedBox(width: 8),
            Text("Wellness & Environment", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green[900],
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Stack(
        children: [
          // 🌿 Background Image with Blurred Overlay
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              blendMode: BlendMode.darken,
              child: Image.network(
                'https://img.pikbest.com/wp/202405/eco-friendly-banner-with-sustainable-green-background-3d-render_9850513.jpg!sw800',
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.greenAccent),
                      SizedBox(height: 20),
                      Text("Analyzing Image...",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

          // 🌿 Glassmorphism Effect UI
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Choose an Image", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.green[50]?.withOpacity(0.5),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: _selectedImage == null
                          ? Icon(Icons.add_a_photo, size: 80, color: Colors.white)
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.upload, color: Colors.white),
                    label: Text("Select Image", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                    ),
                  ),
                  SizedBox(height: 20),

                  // 📜 Image Description after API Response
                  if (_imageDescription != null)
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        "🌱 Description: $_imageDescription",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                    ),

                  SizedBox(height: 10),

                  // 🌍 Motivational Quote
                  Text(
                    "“The earth does not belong to us: we belong to the earth.” 🌍",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
