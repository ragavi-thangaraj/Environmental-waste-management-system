import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageResultPage extends StatefulWidget {
  final File image;
  final Map<String, dynamic> descriptionText; // JSON response containing labels

  ImageResultPage({required this.image, required this.descriptionText});

  @override
  _ImageResultPageState createState() => _ImageResultPageState();
}

class _ImageResultPageState extends State<ImageResultPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _responseText = "Select a tab to fetch data";
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _extractLabels();
  }

  void _extractLabels() {
    try {
      print("🔍 Raw JSON Data: ${widget.descriptionText}");

      var body = widget.descriptionText["body"];
      print("📦 Extracted Body: $body");

      if (body != null && body is Map<String, dynamic> && body.containsKey("labels")) {
        var labelsList = body["labels"];
        print("📝 Labels List Structure: ${jsonEncode(labelsList)}");

        if (labelsList is List<String>) {
          setState(() {
            _labels = labelsList.toSet().toList();
          });
          print("✅ Final Extracted Labels: $_labels");
        } else {
          print("❌ Error: 'labelsList' is not a list of strings!");
          setState(() {
            _labels = [];
            _responseText = "No labels found!";
          });
        }
      } else {
        print("❌ Error: 'body' does not contain 'labels'!");
        setState(() {
          _labels = [];
          _responseText = "No labels found!";
        });
      }
    } catch (e) {
      print("⚠️ Label Extraction Error: $e");
      setState(() {
        _labels = [];
        _responseText = "Error extracting labels.";
      });
    }
  }

  /// Fetch API Key from Firestore and try keys until one succeeds.
  Future<String?> _fetchAPIKey() async {
    try {
      print("🔄 Fetching API Keys from Firestore...");
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection("company")
          .doc("Ih27A2rQKu08ZdZZhZG4")
          .get();

      if (doc.exists && doc.data() != null && doc.data()!.containsKey("api_search")) {
        List<dynamic> apiKeys = doc.data()!["api_search"];

        if (apiKeys.isEmpty) {
          print("❌ No API keys available in Firestore.");
          return null;
        }

        for (String key in apiKeys) {
          print("🔍 Testing API Key: $key");
          bool success = await _testAPIKey(key);
          if (success) {
            print("✅ API Key is valid: $key");
            return key;
          }
        }
      } else {
        print("❌ API Key array not found in Firestore!");
      }
    } catch (e) {
      print("⚠️ Error fetching API Key: $e");
    }
    return null; // Return null if all keys fail
  }

  /// Tests API Key to see if it works.
  Future<bool> _testAPIKey(String apiKey) async {
    try {
      var url = Uri.parse("https://chatgpt-42.p.rapidapi.com/o3mini");
      var response = await http.post(url, headers: {
        "X-RapidAPI-Key": apiKey,
        "Content-Type": "application/json"
      });

      print("🔍 API Key Test Response: ${response.statusCode}");

      return response.statusCode == 200; // ✅ Key is valid
    } catch (e) {
      print("⚠️ Error testing API Key: $e");
      return false;
    }
  }

  Future<void> _fetchData(String query) async {
    if (_labels.isEmpty) {
      print("❌ No labels found, cannot fetch data.");
      setState(() {
        _responseText = "No labels found!";
      });
      return;
    }

    String formattedQuery;
    if (query == "Product Details") {
      formattedQuery =
      "Describe the significance of these items: ${_labels.join(
          ", ")}. Provide 3 advantages and disadvantages.";
    } else if (query == "Environmental Impact") {
      formattedQuery =
      "Explain how these items: ${_labels.join(
          ", ")} impact in our environment or the ecosystem, like how will it help us or the ecosystem what are all the real uses if it is harmfull suggest me the way to make it useful to me and make the environment clean and tide.";
    } else if (query == "Health Impact") {
      formattedQuery =
      "Discuss the benefits and side effects of these items: ${_labels.join(
          ", ")} when consumed or used.";
    } else {
      formattedQuery =
      "Provide the correct disposal methods for these items: ${_labels.join(
          ", ")}.";
    }


    setState(() {
      _isLoading = true;
      _responseText = "Fetching data...";
    });

    print("🔄 Fetching API Key...");
    String? apiKey = await _fetchAPIKey();

    if (apiKey == null) {
      print("❌ No valid API key found.");
      setState(() {
        _isLoading = false;
        _responseText = "This may take a while. Please try again later.";
      });
      return;
    }

    var url = Uri.parse("https://chatgpt-42.p.rapidapi.com/o3mini");

    var headers = {
      "X-RapidAPI-Key": apiKey,
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      "messages": [
        {
          "role": "user",
          "content": formattedQuery,
        }
      ],
      "web_access": false
    });

    print("🚀 Sending API Request...");
    print("📝 Request Body: $body");


    try {
      var response = await http.post(url, headers: headers, body: body);
      print("🔍 Response Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      var data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data["status"] == true && data.containsKey("result")) {
        String extractedText = data["result"];

        setState(() {
          _responseText = extractedText.isNotEmpty
              ? _formatResponseText(extractedText)
              : "No relevant data found!";
          _isLoading = false;
        });
      } else {
        print("❌ API Response Error: ${data["server_code"]}");
        setState(() {
          _responseText = "Unexpected response format!";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("⚠️ Error Fetching Data: $e");
      setState(() {
        _responseText = "Error fetching response!";
        _isLoading = false;
      });
    }
  }

  String _formatResponseText(String text) {
    // Decode UTF-8 characters properly
    text = utf8.decode(text.runes.toList());

    // Replace unwanted characters
    text = text.replaceAll("\\n", "\n").trim();
    text = text.replaceAll(RegExp(r"(?<=\d)\.\s"), ".\n\n");
    text = text.replaceAll("**", "");
    text = text.replaceAll("â", "–"); // Replace dashes
    text = text.replaceAll("â", " "); // Replace spaces
    text = text.replaceAll("â¢", "•"); // Replace bullet points
    text = text.replaceAll("â", "\"").replaceAll("â", "\""); // Replace quotes
    text = text.replaceAll("â¦", "..."); // Replace ellipses
    text = text.replaceAll("â", "'"); // Replace apostrophes

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.green[900],
            elevation: 10,
            pinned: true,
            expandedHeight: 250,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                "",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(1, 1))
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(widget.image, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),  // Darker top for readability
                          Colors.transparent,
                          Colors.green[900]!.withOpacity(0.6), // Green tint at the bottom
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
        body: Column(
          children: [
            Container(
              color: Colors.green[100],
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.green[900],
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green[700],
                onTap: (index) {
                  List<String> queries = ["Product Details", "Environmental Impact", "Health Impact", "Disposal Measures"];
                  _fetchData(queries[index]);
                },
                tabs: [
                  Tab(icon: Icon(Icons.info_outline, color: Colors.green[800]), text: "Product Details"),
                  Tab(icon: Icon(Icons.eco, color: Colors.green[800]), text: "Environmental Impact"),
                  Tab(icon: Icon(Icons.health_and_safety, color: Colors.green[800]), text: "Health Impact"),
                  Tab(icon: Icon(Icons.delete_outline, color: Colors.green[800]), text: "Disposal Measures"),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.green))
                    : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Colors.green[300],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Analysis Result",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          Divider(color: Colors.green[700], thickness: 1),
                          SizedBox(height: 10),
                          Text(
                            _responseText,
                            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
