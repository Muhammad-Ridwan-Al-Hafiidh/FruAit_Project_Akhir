import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:external_path/external_path.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String modelPath; // Pass the selected model path
  final String selectedFruit;

  const MainPage({Key? key, required this.cameras, required this.modelPath, required this.selectedFruit}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  File? _image;
  late Interpreter _interpreter;
  List<String> _labels = ["Matang", "Setengah Matang", "Belum Matang"];
  bool _isRearCamera = true;
  bool _isFlashOn = false;
  List<File> _imagesList = [];
  String _result = "";
  List<double> _confidence = [];
  final int imageSize = 224;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    String fileName = basename(imageFile.path);
    Reference storageReference = FirebaseStorage.instance.ref().child('images/$fileName');

    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.whenComplete(() => null);

    String downloadUrl = await storageReference.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(widget.modelPath); // Use the selected model path
      print("Model loaded successfully from: ${widget.modelPath}");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  void _switchCamera() {
    setState(() {
      _isRearCamera = !_isRearCamera;
      int cameraIndex = _isRearCamera ? 0 : 1;
      _cameraController = CameraController(
        widget.cameras[cameraIndex],
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _cameraController.initialize();
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _cameraController.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  Future<File> _saveImage(XFile image) async {
    final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('$downloadPath/$fileName');

    try {
      await file.writeAsBytes(await image.readAsBytes());
    } catch (e) {
      print('Error saving image: $e');
    }

    return file;
  }

  Future<void> saveImageDetailsToFirestore(String imageUrl, String fruitName, String result, String userId) async {
    CollectionReference images = FirebaseFirestore.instance.collection('images');

    await images.add({
      'url': imageUrl,
      'buah': fruitName,
      'result': result,
      'user_id': userId,
    });
  }
 Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      final savedImage = await _saveImage(image);

      // Classify the image
      await _classifyImage(savedImage);

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        print('User ID before upload: $userId');

        // Upload the image to Firebase Storage
        String imageUrl = await uploadImageToStorage(savedImage);

        // Save the image details to Firestore with the selected fruit name
        await saveImageDetailsToFirestore(imageUrl, widget.selectedFruit, _result, userId); // Use selectedFruit for buah

        setState(() {
          _image = savedImage;
          _imagesList.add(savedImage);
        });
      } else {
        print('User is not authenticated');
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File selectedImage = File(pickedFile.path);

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Upload the image to Firebase Storage
        String imageUrl = await uploadImageToStorage(selectedImage);

        // Save the image details to Firestore with the selected fruit name
        await saveImageDetailsToFirestore(imageUrl, widget.selectedFruit, _result, userId); // Use selectedFruit for buah

        setState(() {
          _image = selectedImage;
          _imagesList.add(_image!);
        });
      } else {
        print('User is not authenticated');
      }
    }
  }

  Future<void> _classifyImage(File image) async {
  img.Image? imageInput = img.decodeImage(await image.readAsBytes());
  if (imageInput == null) return;

  img.Image resizedImage = img.copyResize(imageInput, width: imageSize, height: imageSize);

  var inputBuffer = Float32List(1 * imageSize * imageSize * 3);
  var pixelIndex = 0;
  for (var y = 0; y < imageSize; y++) {
    for (var x = 0; x < imageSize; x++) {
      var pixel = resizedImage.getPixel(x, y);
      inputBuffer[pixelIndex++] = pixel.r / 255.0;  // Red
      inputBuffer[pixelIndex++] = pixel.g / 255.0;  // Green
      inputBuffer[pixelIndex++] = pixel.b / 255.0;  // Blue
    }
  }

  // Adjust input and output shapes based on your model's requirements
  var inputShape = [1, imageSize, imageSize, 3];
  var outputShape = [1, 3];  // Update this to [1, 3] to match the output shape returned by the model

  var outputBuffer = List.filled(1 * 3, 0).reshape(outputShape);  // Adjust output buffer size to 3

  // Run the interpreter with the updated shapes
  _interpreter.run(inputBuffer.reshape(inputShape), outputBuffer);

  // Convert the output to a list of doubles
  var confidences = (outputBuffer[0] as List).map((v) => v as double).toList();

  var maxPos = 0;
  var maxConfidence = 0.0;
  for (var i = 0; i < confidences.length; i++) {
    if (confidences[i] > maxConfidence) {
      maxConfidence = confidences[i];
      maxPos = i;
    }
  }

  setState(() {
    _result = _labels[maxPos];
    _confidence = confidences.map((conf) => conf * 100).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return CameraPreview(_cameraController);
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  Column(
                    children: [
                      Container(
                        height: 60,
                        child: Card(
                          color: Color.fromARGB(102, 0, 0, 0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: _toggleFlash,
                                  child: Icon(
                                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _switchCamera,
                                  child: Icon(
                                    _isRearCamera ? Icons.camera_rear : Icons.camera_front,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _pickImageFromGallery,
                                  child: Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _takePicture,
                                  child: Icon(
                                    Icons.camera,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_image != null) ...[
              Center(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Text('Classification: $_result'),
              Text('Confidence: ${_confidence.isNotEmpty ? _confidence.join(", ") : "N/A"}'),
            ],
          ],
        ),
      ),
    );
  }
}
