import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fruait/model/model/history_model.dart';
import 'history_detail.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<ImagesModel> _images = [];
  late String _userId;

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
      _fetchImages();
    } else {
      print("No user is currently logged in.");
    }
  }

  Future<void> _fetchImages() async {
    if (_userId.isEmpty) {
      return;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('images')
          .where('user_id', isEqualTo: _userId)
          .get();

      List<ImagesModel> images = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Fetched data: $data'); // Debug print
        ImagesModel model = ImagesModel.fromJson(data);
        print('Created ImagesModel: $model'); // Debug print
        images.add(model);
      }
      setState(() {
        _images = images;
      });
      print('Total images fetched: ${_images.length}');
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  String _getAssetImage(String? buah) {
    print('Getting asset image for fruit: $buah'); // Debug print
    if (buah == null || buah.isEmpty) {
      return 'assets/background.png';
    }
    String assetPath;
    switch (buah.trim().toLowerCase()) {
      case 'banana':
        assetPath = 'assets/pisang.png';
        break;
      case 'tomato':
        assetPath = 'assets/tomat.png';
        break;
      case 'mangga':
        assetPath = 'assets/mangga.png';
        break;
      case 'jambu':
        assetPath = 'assets/jambu.png';
        break;
      case 'jeruk':
        assetPath = 'assets/jeruk.png';
        break;
      default:
        assetPath = 'assets/background.png';
        break;
    }
    print('Selected asset path: $assetPath'); // Debug print
    return assetPath;
  }

  void navigateToDetailPage(String url) {
    print('Navigating to URL: $url');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 30),
                  child: Text(
                    'History Kematangan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 37,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final image = _images[index];
                      print('Building item for fruit: ${image.buah}'); // Debug print
                      return GestureDetector(
                        onTap: () => navigateToDetailPage(image.url),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Card(
                            child: Column(
                              children: [
                                Image.asset(
                                  _getAssetImage(image.buah),
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading asset image: $error');
                                    return Icon(Icons.error);
                                  },
                                ),
                                Text(
                                  image.buah ?? 'Unknown Fruit',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
      ),
    );
  }
}