import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyReportsScreen extends StatelessWidget {
  final String userId;

  const MyReportsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Query reportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Not Approved');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Pending Reports',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: Colors.black26,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reportsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No pending reports found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              String complaintText = data['complaintText'] ?? '';
              String dateStr = data['date'] ?? '';
              String category = data['category'] ?? '';
              String reportId = docs[index].id;

              // Truncate complaint text for a concise preview.
              String shortComplaint = complaintText.length > 40
                  ? '${complaintText.substring(0, 40)}...'
                  : complaintText;

              // Get image string for hero animation (if any).
              String imageBase64 = data['image'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailScreen(
                        reportId: reportId,
                        complaintText: complaintText,
                        date: dateStr,
                        quantity: data['quantity'] ?? 0,
                        weightPerKg: data['weightPerKg'] is int
                            ? (data['weightPerKg'] as int).toDouble()
                            : (data['weightPerKg'] ?? 0.0),
                        status: data['status'] ?? '',
                        userId: userId,
                        imageBase64: imageBase64,
                        category: category,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.report, color: Colors.green),
                    ),
                    title: Text(
                      category,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          shortComplaint,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  final String complaintText;
  final String date;
  final int quantity;
  final double weightPerKg;
  final String status;
  final String userId;
  final String imageBase64;
  final String category;

  const ReportDetailScreen({
    Key? key,
    required this.reportId,
    required this.complaintText,
    required this.date,
    required this.quantity,
    required this.weightPerKg,
    required this.status,
    required this.userId,
    required this.imageBase64,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Decode the Base64 image.
    Uint8List? imageBytes;
    if (imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (e) {
        imageBytes = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report Details',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: Colors.black26,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBytes != null)
              Hero(
                tag: 'reportImage_$reportId',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    imageBytes,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              category,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            Text(
              'Complaint:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              complaintText,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.confirmation_number, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  'Quantity: $quantity',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.scale, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  'Weight per Kg: $weightPerKg',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  'Status: $status',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    "Loading user info...",
                    style: TextStyle(fontSize: 16),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text(
                    "Unknown user",
                    style: TextStyle(fontSize: 16),
                  );
                }
                final userData =
                snapshot.data!.data() as Map<String, dynamic>;
                String userName = userData['name'] ?? "Unknown";
                return Row(
                  children: [
                    const Icon(Icons.person, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      'Reported by: $userName',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
