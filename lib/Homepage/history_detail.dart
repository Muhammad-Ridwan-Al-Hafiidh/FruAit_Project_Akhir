import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String imageUrl;

  const DetailPage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Detail'),
      ),
      body: Center(
        child: imageUrl.isNotEmpty
            ? Image.network(imageUrl) // Use Image.network for URLs
            : Text('No image available'), // Handle empty URL case
      ),
    );
  }
}
