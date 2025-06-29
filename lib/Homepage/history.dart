import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'history_detail.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map<String, dynamic>> _images = [];
  late String _userId;
  bool _isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      await _fetchImages();
    }
  }

  Future<void> _fetchImages() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('images')
          .where('user_id', isEqualTo: _userId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> images = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        images.add({
          'buah': data['buah'] ?? 'Unknown',
          'result': data['result'] ?? 'Unknown',
          'color': data['detected_color'] ?? 'Unknown',
          'url': data['url'] ?? '',
          'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
        });
      }

      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching history: $e')),
      );
    }
  }

  String _getAssetImage(String buah) {
    switch (buah.toLowerCase()) {
      case 'pisang':
        return 'assets/pisang.png';
      case 'tomat':
        return 'assets/tomat.png';
      case 'mangga':
        return 'assets/mangga.png';
      case 'jambu':
        return 'assets/guava.png';
      case 'jeruk':
        return 'assets/jeruk.png';
      default:
        return 'assets/background.png';
    }
  }

  Color _getStatusColor(String result) {
    switch (result.toLowerCase()) {
      case 'matang':
        return Colors.green;
      case 'setengah matang':
        return Colors.orange;
      case 'belum matang':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20, bottom: 30),
                child: Text(
                  'History Kematangan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _images.isEmpty
                        ? const Center(
                            child: Text(
                              'No history found',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              final item = _images[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailPage(
                                        imageUrl: item['url'],
                                        fruitName: item['buah'],
                                        result: item['result'],
                                        color: item['color'],
                                        timestamp: item['timestamp'],
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          _getAssetImage(item['buah']),
                                          width: 80,
                                          height: 80,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.image, size: 80);
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['buah'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(item['result']),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    item['result'],
                                                    style: TextStyle(
                                                      color: _getStatusColor(item['result']),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd MMM yyyy - HH:mm').format(item['timestamp']),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right),
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
      ),
    );
  }
}