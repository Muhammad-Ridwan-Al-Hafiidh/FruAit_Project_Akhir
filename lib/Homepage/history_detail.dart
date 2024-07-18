import 'package:flutter/material.dart';

class HistoryDetailPage extends StatelessWidget {
  final String name;
  final String image;
  final String status;
  final String icon;

  const HistoryDetailPage({
    Key? key,
    required this.name,
    required this.image,
    required this.status,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(icon, width: 400,height: 200,), // Display the image width: 100, height: 100),
            SizedBox(height: 20),
            Text(
              'Status: $status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
