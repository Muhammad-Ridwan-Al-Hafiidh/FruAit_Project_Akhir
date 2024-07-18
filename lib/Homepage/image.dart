
  

import 'dart:io';

import 'package:flutter/material.dart';

class ImageDisplayPage extends StatelessWidget {
  final String imagePath;

  const ImageDisplayPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured Image'),
      ),
        body: Center(
        child: Container(
          width: screenWidth * 1,
          height: screenHeight * 0.4,
          decoration: BoxDecoration(
            
          ),
          child: Card(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}